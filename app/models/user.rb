# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#

class User < ActiveRecord::Base
  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable,
         :confirmable

  has_many :accounts, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :scheduled_transactions, dependent: :destroy
  has_many :transaction_endpoints, dependent: :destroy

  # Retrieve an account for this user.  By default, returns the default
  # account.
  # The account identifier may also be a string corresponding to the name of
  # the account you want to retrieve
  def account(identifier = :default)
    identifier == :default ? default_account : accounts.where(name: identifier).first
  end

  # Deposit money into the given account.  By default, deposits to the
  # :default account.
  # Deposit data is a hash including
  #   - from: (required) A TransactionEndpoint identifier (either an instance
  #           or a string corresponding to the label of the endpoint)
  #   - category: A string or Category instance.  If a string and a category
  #               does not exist, creates a new one
  #   - transaction_at: a DateTime (or parseable datetime string) indicating
  #                     the date this deposit occured, defaults to Time.now
  #
  # You may optionally include a currency identifier, though the default
  #currency will be used if this is omitted.  If included, it should be passed
  # as the second parameteer, ie:
  #   `user.deposit(100, 'usd', other_params)
  def deposit(amount, *args)
    do_transaction :deposit, amount, *args
  end

  # Withdraw money from the given account.  By default, withdraws from the
  # :default account.
  # Deposit data is a hash including
  #   - to: (required) A TransactionEndpoint identifier (either an instance or
  #         a string corresponding to the label of the endpoint)
  #   - category: A string or Category instance.  If a string and a category
  #               does not exist, creates a new one
  #   - transaction_at: a DateTime (or parseable datetime string) indicating
  #                     the date this deposit occured, defaults to Time.now
  #
  # You may optionally include a currency identifier, though the default
  # currency will be used if this is omitted.  If included, it should be
  # passed as the second parameteer, ie:
  #   `user.withdraw(100, 'usd', other_params)
  def withdraw(amount, *args)
    do_transaction :withdraw, amount, *args
  end

  # Transfer money between accounts.  By default, withdraws from the :default account.
  # Deposit data is a hash including
  #   - to: (required) An account identifier (either an instance or a string
  #          corresponding to the name of the account)
  #   - transaction_at: a DateTime (or parseable datetime string) indicating
  #                     the date this deposit occured, defaults to Time.now
  #
  # You may optionally include a currency identifier, though the default
  # currency will be used if this is omitted.  If included, it should be
  # passed as the second parameteer, ie:
  #   `user.transfer(100, 'usd', other_params)
  def transfer(amount, *args)
    do_transaction :transfer, amount, *args
  end

  # Schedule a deposit at some point in the future, using the given options
  #   - on:         This deposit will be made once on the given date
  #   - schedule:   This deposit is recurring, following the rules in the
  #                 given IceCube::Schedule
  #   - other parameters as defined in `deposit`
  #
  # You may optionally include a currency identifier, though the default
  # currency will be used if this is omitted.  If included, it should be
  # passed as the second parameteer, ie:
  #   `user.will_deposit(100, 'usd', other_params)
  def will_deposit(amount, *args)
    do_scheduled_transaction(:deposit, amount, *args)
  end

  # Schedule a withdrawal at some point in the future, using the given options
  #   - on:         This withdrawal will be made once on the given date
  #   - schedule:   This withdrawal is recurring, following the rules in the
  #                 given IceCube::Schedule
  #   - other parameters as defined in `withdraw`
  #
  # You may optionally include a currency identifier, though the default
  # currency will be used if this is omitted.  If included, it should be
  # passed as the second parameteer, ie:
  #   `user.will_withdraw(100, 'usd', other_params)
  def will_withdraw(amount, *args)
    do_scheduled_transaction(:withdraw, amount, *args)
  end

  # Schedule a transfer at some point in the future, using the given options
  #   - on:         This transfer will be made once on the given date
  #   - schedule:   This transfer is recurring, following the rules in the
  #                 given IceCube::Schedule
  #   - other parameters as defined in `transfer`
  #
  # You may optionally include a currency identifier, though the default
  # currency will be used if this is omitted.  If included, it should be
  # passed as the second parameteer, ie:
  #   `user.will_transfer(100, 'usd', other_params)
  def will_transfer(amount, *args)
    do_scheduled_transaction(:transfer, amount, *args)
  end

  # Iterates scheduled transactions set to be run on the given date
  def each_scheduled(date)
    scheduled_transactions.each do |t|
      occurs = t.schedule.nil? ? t.transaction_at.to_date == date.to_date : (t.transaction_at.to_date <= date.to_date && t.schedule.occurs_on?(date))
      yield(t) if occurs && block_given?
    end
  end

  # Returns the balance for this user for the given date.  The balance is
  # calculated across all known accounts.
  def balance(date = Time.now)
    total = 0
    accounts.each do |account|
      total += account.balance(date)
    end

    total
  end

  alias :net_worth :balance

  # Retrieve a transaction set for this user, using the passed filters.
  def transaction_set(filters = {})
    filters[:user_id] = id
    Mny::TransactionSet.new(filters)
  end

  # Retrieve a forecast for this user for the given number of days
  #  (defaults to 30)
  def forecast(opts = {})
    Mny::Forecast.new opts.merge(for: self)
  end

  private

  # Returns the default account for this user, or the first account, if
  # no default has been set.
  def default_account
    accounts.where(is_default: true).first || accounts.first
  end

  # Pass a transaction to the given account
  def do_transaction(type, amount, *args)
    key = transaction_keys[type]

    account = account_from_args args, key
    raise "No matching account for this transaction" if account.nil?

    account.send type, amount, *args
  end

  # Pass a scheduled transaction to the given account
  def do_scheduled_transaction(type, amount, *args)
    key = transaction_keys[type]

    account = account_from_args args, key
    raise "No matching account for this transaction" if account.nil?

    account.send :"will_#{ type }", amount, *args
  end

  # Returns the known transaction key mapping from parameters to transaction
  # types (ie: :to => :deposit)
  def transaction_keys
    {
      deposit:  :to,
      withdraw: :from,
      transfer: :from
    }
  end

  # Get an account instance from method arguments passed to a method like
  # deposit or withdraw.
  # The key param should be the key in the parameters passed to the calling
  # method that may contain an account identifier or instance
  def account_from_args(args, key = :to)
    p = args.first.is_a?(String) ? args.last : args.first

    account = (p[key].nil?) ? default_account : (p[key].is_a?(Account) ? p[key] : account(p[key]))
    p.delete key

    account
  end
end
