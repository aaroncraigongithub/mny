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
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  has_many :accounts
  has_many :categories
  has_many :transactions
  has_many :scheduled_transactions
  has_many :transaction_endpoints

  # Retrieve an account for this user.  By default, returns the default account.
  # The account identifier may also be a string corresponding to the name of the account you want to retrieve
  def account(identifier = :default)
    identifier == :default ? default_account : accounts.where(name: identifier).first
  end

  # Deposit money into the given account.  By default, deposits to the :default account.
  # Deposit data is a hash including
  #   - from: (required) A TransactionEndpoint identifier (either an instance or a string corresponding to the label of the endpoint)
  #   - category: A string or Category instance.  If a string and a category does not exist, creates a new one
  #   - transaction_at: a DateTime (or parseable datetime string) indicating the date this deposit occured, defaults to Time.now
  #
  # You may optionally include a currency identifier, though the default currency will be used if this is omitted.  If included, it should be passed as the second parameteer, ie:
  #   `user.deposit(100, 'usd', other_params)
  def deposit(amount, *args)
    do_transaction :deposit, amount, *args
  end

  # Withdraw money from the given account.  By default, withdraws from the :default account.
  # Deposit data is a hash including
  #   - to: (required) A TransactionEndpoint identifier (either an instance or a string corresponding to the label of the endpoint)
  #   - category: A string or Category instance.  If a string and a category does not exist, creates a new one
  #   - transaction_at: a DateTime (or parseable datetime string) indicating the date this deposit occured, defaults to Time.now
  #
  # You may optionally include a currency identifier, though the default currency will be used if this is omitted.  If included, it should be passed as the second parameteer, ie:
  #   `user.withdraw(100, 'usd', other_params)
  def withdraw(amount, *args)
    do_transaction :withdraw, amount, *args
  end

  # Transfer money between accounts.  By default, withdraws from the :default account.
  # Deposit data is a hash including
  #   - to: (required) An account identifier (either an instance or a string corresponding to the name of the account)
  #   - transaction_at: a DateTime (or parseable datetime string) indicating the date this deposit occured, defaults to Time.now
  #
  # You may optionally include a currency identifier, though the default currency will be used if this is omitted.  If included, it should be passed as the second parameteer, ie:
  #   `user.transfer(100, 'usd', other_params)
  def transfer(amount, *args)
    do_transaction :transfer, amount, *args
  end

  # Returns the balance for this user for the given date.  The balance is calculated across all known accounts.
  def balance(date = Time.now)
    accounts.collect { |account| account.balance(date) }.reduce(:+)
  end

  alias :net_worth :balance

  private

  def default_account
    accounts.where(is_default: true).first || accounts.first
  end

  def do_transaction(type, amount, *args)
    key = {
      deposit:  :to,
      withdraw: :from,
      transfer: :from
    }[type]

    account = account_from_args args, key
    raise "No matching account for this transaction" if account.nil?

    account.send type, amount, *args
  end

  # Get an account instance from method arguments passed to a method like deposit or withdraw.
  # The key param should be the key in the parameters passed to the calling method that may contain
  # an account identifier or instance
  def account_from_args(args, key = :to)
    p = args.first.is_a?(String) ? args.last : args.first

    account = (p[key].nil?) ? default_account : (p[key].is_a?(Account) ? p[key] : account(p[key]))
    p.delete key

    account
  end
end
