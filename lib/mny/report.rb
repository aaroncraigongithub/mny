# Generate reports from a collection of transaction instances

class Mny::Report

  def initialize(transactions, params = {})
    @transactions     = transactions.to_a
    @starting_balance = params[:starting_balance] || 0
    @balances         = {}
  end

  # Iterates the transactions in this set
  def each
    sorted_transactions.each do |t|
      yield t if block_given?
    end
  end

   # Returns the transaction date of the earliest transaction in the current set
  def start_date
    @transactions.empty? ? nil : sorted_transactions.first.transaction_at
  end

  # Returns the transaction date of the latest transaction in the current set
  def end_date
    @transactions.empty? ? nil : sorted_transactions.last.transaction_at
  end

  # Returns all of the accounts included in this transaction set
  def accounts
    @transactions.collect(&:account).uniq
  end

  # Returns all transaction endpoints included in this transaction set
  def transaction_endpoints
    @transactions.to_a.delete_if{ |t| t.transaction_endpoint.nil? }.collect(&:transaction_endpoint).uniq
  end

  # Returns all transaction types included in this transaction set
  def transaction_types
    @transactions.empty? ? nil : @transactions.collect(&:transaction_type).uniq
  end

  # All categories included in this transaction set
  def categories
    @transactions.empty? ? nil : @transactions.delete_if{ |t| t.category.nil? }.collect(&:category).uniq
  end

  # All status values included in this transaction set
  def status
    @transactions.empty? ? nil : @transactions.collect(&:status).uniq
  end

  # Returns the balance for this set on the given date.  Defaults to the final date in the set.
  def balance(date = nil)
    update_balances
    date = end_date if date.nil?

    raise "Transaction set begins later than this date" if date < start_date
    raise "Transaction set ends before this date" if date > end_date

    @balances[date.to_date]
  end

  # Returns the difference between the highest balance and the lowest balance in this transaction set up to the given date.  Defaults to the last day in the set.
  def variation(date = nil)
    date = end_date if date.nil?

    raise "Transaction set begins later than this date" if date < start_date
    raise "Transaction set ends before this date" if date > end_date

    high(date) - low(date)
  end

  # Returns the highest balance for the set up to the given date.  Defaults to the last day in the set.
  def high(date = nil)
    update_balances
    edge_total(:high, date)
  end

  # Returns the lowest balance for the set up to the given date.  Defaults to the last day in the set.
  def low(date = nil)
    update_balances
    edge_total(:low, date)
  end

  # Returns a hash containing negative balances in this set up to the given date.  Each key corresponds to a date, and the value is the negative balance at the end of that day
  def negative_balances(date = nil)
    update_balances
    date = end_date if date.nil?

    raise "Transaction set begins later than this date" if date < start_date
    raise "Transaction set ends before this date" if date > end_date

    negatives = {}
    @balances.each do |d, b|
      negatives[d] = b if b < 0 && d <= date.to_date
    end

    negatives
  end

  # Returns an array of transaction data for the current set.
  # Each entry in the array is a hash containing:
  #   - id:       the transaction id
  #   - date:     the transaction date
  #   - type:     the transaction type
  #   - from:     the endpoint / account this transaction came from
  #   - to:       the endpoint / account this transaction goes to
  #   - category: the category name
  #   - status:   the transaction status
  #   - amount:   the adjusted amount
  #   - balance:  the running balance
  def report(date = nil)
    date    = end_date if date.nil?
    balance = @starting_balance
    data    = []

    sorted_transactions.each do |t|
      balance += t.adjusted_amount

      row = {
        id:       t.id,
        account:  t.account.name,
        date:     t.transaction_at.to_date,
        type:     t.transaction_type,
        from:     t.from.name,
        to:       t.to.name,
        category: t.category.nil? ? 'Uncategorized' : t.category.name,
        amount:   display_cents(t.amount),
        balance:  display_cents(balance)
      }

      row[:status] = t.status || :unknown if t.is_a? Transaction
      data<< row
    end

    data
  end

  private

  # Sort transactions by transaction date
  def sorted_transactions(date = nil)
    set = date.nil? ? @transactions : @transactions.keep_if{ |t| t.transaction_at <= date.end_of_day }
    set.sort_by(&:transaction_at)
  end

  # Returns the highest or lowest total for this set, considering transactions up to and including the given date.
  # Transactions occurring on the same day are grouped, and the final balance for the day is used to calculate the high / low
  def edge_total(type = :high, date = nil)
    date = end_date if date.nil?

    raise "Transaction set begins later than this date" if date < start_date
    raise "Transaction set ends before this date" if date > end_date

    memo = nil
    @balances.each do |d, b|
      next if d > date.to_date

      if type == :high
        memo = b if memo.nil? or b > memo
      else
        memo = b if memo.nil? or b < memo
      end
    end

    memo
  end

  # Generate a hash of balance values per day
  def update_balances
    @balances = {}
    balance   = @starting_balance
    sorted_transactions.each do |t|
      key = t.transaction_at.to_date

      balance += t.adjusted_amount

      @balances[key] = balance
    end

    # fill in missing dates for easy lookup
    last_date     = nil
    last_balance  = nil
    @balances.keys.sort.each do |date|
      while last_date && last_date < (date - 1.day).to_date
        last_date = (last_date + 1.day).to_date
        @balances[last_date] = last_balance
      end

      last_date    = date
      last_balance = @balances[date]
    end
  end

  # Display the given integer as a currency amount (@TODO use the currency of the transaction)
  def display_cents(cents)
    sprintf("$ %5.02f", cents.to_f / 100)
  end
end
