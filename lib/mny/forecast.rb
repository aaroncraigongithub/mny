# # Mny::Forecast
#
# Forecast a financial situation given the current balance and some scheduled transactions

class Mny::Forecast

  # Forecasts should be created for a specific user, ie:
  # forecast = Mny::Forecast.new for: user, days: some_int
  #
  # Days defaults to 30
  def initialize(params)
    days = params[:days] || 30

    @user         = params[:for]
    @transactions = nil
    @reporter     = nil
    @end_date     = Time.now + days.days
  end

  # Returns the transaction date of the earliest transaction in the current set
  def start_date
    Time.now
  end

  # Returns the transaction date of the latest transaction in the current set
  def end_date
    @end_date
  end

  # Returns all of the accounts included in this transaction set
  def accounts
    forecast!
    @reporter.accounts
  end

  # Returns all transaction endpoints included in this transaction set
  def transaction_endpoints
    forecast!
    @reporter.transaction_endpoints
  end

  # Returns all transaction types included in this transaction set
  def transaction_types
    forecast!
    @reporter.transaction_types
  end

  # All categories included in this transaction set
  def categories
    forecast!
    @reporter.categories
  end

  # All status values included in this transaction set
  def status
    forecast!
    @reporter.status
  end

  # Returns the balance for this set on the given date.  Defaults to the final date in the set.
  def balance(date = nil)
    forecast!
    @reporter.balance date
  end

  # Returns the difference between the highest balance and the lowest balance in this transaction set up to the given date.  Defaults to the last day in the set.
  def variation(date = nil)
    forecast!
    @reporter.variation date
  end

  # Returns the highest balance for the set up to the given date.  Defaults to the last day in the set.
  def high(date = nil)
    forecast!
    @reporter.high date
  end

  # Returns the lowest balance for the set up to the given date.  Defaults to the last day in the set.
  def low(date = nil)
    forecast!
    @reporter.low date
  end

  # Returns a hash containing negative balances in this set up to the given date.  Each key corresponds to a date, and the value is the negative balance at the end of that day
  def negative_balances(date = nil)
    forecast!
    @reporter.negative_balances date
  end

  # Returns a report of the current transaction set.
  # See Mny::Report#report
  def report(date = nil)
    forecast!
    @reporter.report date
  end

  private

  # Run the prediction routine, populating @transactions with Transaction instances, with a promise to never save the instances.
  def forecast!
    @transactions = []

    # Start with a first deposit which is the user's current net worth
    dt = Time.now
    until dt.to_date > @end_date.to_date do
      dt = dt + 1.day

      @user.each_scheduled(dt) do |st|
        attrs = {
          user_id:                @user.id,
          account_id:             st.account.id,
          transaction_endpoint:   st.transaction_endpoint,
          transfer_to:            st.transfer_to,
          transfer_from:          st.transfer_from,
          category:               st.category,
          transaction_type:       st.transaction_type,
          amount:                 st.amount,
          transaction_at:         dt,
          currency:               st.currency
        }

        @transactions<< Transaction.new(attrs)
      end
    end

    @reporter = Mny::Report.new @transactions, starting_balance: @user.net_worth
  end
end
