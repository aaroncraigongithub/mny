# == Schema Information
#
# Table name: accounts
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  name       :string(255)
#  is_default :boolean
#  created_at :datetime
#  updated_at :datetime
#

class Account < ActiveRecord::Base
  validates :name, uniqueness: true

  belongs_to :user
  has_many :transactions

  # Deposit money into this account.
  # Deposit data is a hash including
  #   - from: (required) A TransactionEndpoint identifier (either an instance or a string corresponding to the label of the endpoint)
  #   - category: A string or Category instance.  If a string and a category does not exist, creates a new one
  #   - transaction_at: a DateTime (or parseable datetime string) indicating the date this deposit occured, defaults to Time.now
  #
  # You may optionally include a currency identifier, though the default currency will be used if this is omitted.  If included, it should be passed as the second parameteer, ie:
  #   `account.deposit(100, 'usd', other_params)
  def deposit(amount, *args)
    do_transaction :deposit, amount, *args
  end

  # Withdraw money from this account.
  # Deposit data is a hash including
  #   - to: (required) A TransactionEndpoint identifier (either an instance or a string corresponding to the label of the endpoint)
  #   - category: A string or Category instance.  If a string and a category does not exist, creates a new one
  #   - transaction_at: a DateTime (or parseable datetime string) indicating the date this deposit occured, defaults to Time.now
  #
  # You may optionally include a currency identifier, though the default currency will be used if this is omitted.  If included, it should be passed as the second parameteer, ie:
  #   `account.withdraw(100, 'usd', other_params)
  def withdraw(amount, *args)
    do_transaction :withdrawal, amount, *args
  end

  # Transfer money from this account to another.
  # Deposit data is a hash including
  #   - to: (required) An Account identifier (either an instance or a string corresponding to the name of the account)
  #   - transaction_at: a DateTime (or parseable datetime string) indicating the date this deposit occured, defaults to Time.now
  #
  # You may optionally include a currency identifier, though the default currency will be used if this is omitted.  If included, it should be passed as the second parameteer, ie:
  #   `account.transfer(100, 'usd', other_params)
  def transfer(amount, *args)
    do_transaction :transfer_out, amount, *args
  end

  # Get the balance for this account for a given date.  Defaults to today.
  # All transactions on the given date will be used, and the time portion of the date is ignored.
  def balance(date = Time.now)
    total = 0

    transactions.sort_by(&:transaction_at).each do |transaction|
      break if transaction.transaction_at.end_of_day > date.end_of_day

      total += transaction.adjusted_amount
    end

    total
  end

  # For future use
  def Account.default_currency
    'usd'
  end

  private

  def do_transaction(type, amount, *args)
    currency    = Account.default_currency
    transaction = {}

    if args.first.is_a? String
      currency = args.first
      transaction = args.last
    else
      transaction = args.first
    end

    raise "Transaction data must be a hash" unless transaction.is_a? Hash

    t_data = {
      status:         'unknown',
      transaction_at: Time.now,
      currency:       currency
      }.merge(transaction)

    t_data[:transaction_type] = type.to_s
    t_data[:user_id]          = user.id
    t_data[:amount]           = amount

    endpoint_key = {
      deposit:      :from,
      withdrawal:   :to,
      transfer_out: :to
    }[type]

    endpoint_id_key = type == :transfer_out ? :transfer_to : :transaction_endpoint_id

    if t_data[endpoint_key].nil?
      raise "Missing the #{ type == :deposit ? 'source' : 'destination' } of this transaction."
    elsif t_data[endpoint_key].is_a? TransactionEndpoint or t_data[endpoint_key].is_a? Account
      t_data[endpoint_id_key] = t_data[endpoint_key].id
      t_data[endpoint_id_key] = t_data[endpoint_key].id
    else
      if type == :transfer_out
        a = user.accounts.where(name: t_data[endpoint_key]).first
        raise "Could not find an account named '#{ t_data[endpoint_key] }" if a.nil?
        t_data[endpoint_id_key] = a.id
      else
        te = user.transaction_endpoints.where(label: t_data[endpoint_key]).first || user.transaction_endpoints.create!(label: t_data[endpoint_key])
        t_data[endpoint_id_key] = te.id
      end
    end
    t_data.delete endpoint_key

    unless t_data[:category].nil?
      if t_data[:category].is_a? Category
        t_data[:category_id] = t_data[:category].id
      else
        category = categories.where(name: t_data[:category]).first
        t_data[:category_id] = category.id unless category.nil?
      end
      t_data.delete :category
    end

    if type == :transfer_out
      incoming_t = t_data.clone
      incoming_t.delete :transfer_to

      incoming_t[:transfer_from] = id
      incoming_t[:transaction_type] = :transfer_in

      Account.find(t_data[:transfer_to]).transactions.create! incoming_t
    end

    transactions.create! t_data
  end
end
