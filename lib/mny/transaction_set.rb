# # Mny::TransactionSet
#
# An inteface for analyzing transactions in Mny.
#
# ## Basic usage
#
# You can access transaction sets through a user instance.  In fact, you should ONLY make instances using `user.transaction_set` so as to avoid potentially leaking user transaction data between accounts.  More on that below.
#
# ```
# user = User.find(id)
# set = user.transaction_set(some_filters)
# ```
# ## Filters
#
# You can use the following filters
#
# ## Security implications of using TransactionSet outside of a user instance.
#
# Consider
#
# ```
# set = Mny::TransactionSet.new(some_filters)
# # Contains transactions from potentially many different users!
# ```
#
# In some slim file:
# ```
# .transactions
#   = transaction_table(set)
# ```
#
# The current user will see other user's data.
#
# Instead
# ```
# user = User.find(id)
# set = user.transaction_set(some_filters)
# # this set ONLY contains transactions for this user
# ```

class Mny::TransactionSet

  # Instantiate a set with the given filters.
  def initialize(filters = {})
    @filters                = filters
    @transactions           = nil
    @filtered               = false
    @reporter               = nil
  end

  # Iterate through this set's transactions.
  def each
    filter!
    @reporter.each do |t|
      yield t if block_given?
    end
  end

  # Return a count of the transactions in this set
  def count
    filter!
    @transactions.nil? ? 0 : @transactions.count
  end

  # Returns a new TransactionSet that contains an intersection of this set and the passed set's transactions
  def &(transaction_set)
    merge_with 'intersection', transaction_set
  end

  # Returns a new TransactionSet that contains a union of this set and the passed set's transactions
  def +(transaction_set)
    merge_with 'union', transaction_set
  end

  # Returns the transaction date of the earliest transaction in the current set
  def start_date
    filter!
    @reporter.start_date
  end

  # Returns the transaction date of the latest transaction in the current set
  def end_date
    filter!
    @reporter.end_date
  end

  # Returns all of the accounts included in this transaction set
  def accounts
    filter!
    @reporter.accounts
  end

  # Returns all transaction endpoints included in this transaction set
  def transaction_endpoints
    filter!
    @reporter.transaction_endpoints
  end

  # Returns all transaction types included in this transaction set
  def transaction_types
    filter!
    @reporter.transaction_types
  end

  # All categories included in this transaction set
  def categories
    filter!
    @reporter.categories
  end

  # All status values included in this transaction set
  def status
    filter!
    @reporter.status
  end

  # Returns the balance for this set on the given date.  Defaults to the final date in the set.
  def balance(date = nil)
    filter!
    @reporter.balance date
  end

  # Returns the difference between the highest balance and the lowest balance in this transaction set up to the given date.  Defaults to the last day in the set.
  def variation(date = nil)
    filter!
    @reporter.variation date
  end

  # Returns the highest balance for the set up to the given date.  Defaults to the last day in the set.
  def high(date = nil)
    filter!
    @reporter.high date
  end

  # Returns the lowest balance for the set up to the given date.  Defaults to the last day in the set.
  def low(date = nil)
    filter!
    @reporter.low date
  end

  # Returns a hash containing negative balances in this set up to the given date.  Each key corresponds to a date, and the value is the negative balance at the end of that day
  def negative_balances(date = nil)
    filter!
    @reporter.negative_balances date
  end

  # Returns a report of the current transaction set.
  # See Mny::Report#report
  def report(date = nil)
    filter!
    @reporter.report date
  end

  private

  # Worker method for & and +
  # Returns a new TransactionSet with a union or intersection of this set and the input set
  def merge_with(op, transaction_set)
    filters = (op == 'union') ? union_filters(transaction_set) : intersect_filters(transaction_set)
    Mny::TransactionSet.new(filters)
  end

  # Returns the intersection of our filters and another set's filters.
  # This changes the keys in the following ways:
  #  - Array values are intersected (ie, transaction_type: [:deposit, :withdrawal] & transaction_type: [:deposit] => transaction_type: [:deposit])
  #  - Scalar values are kept if they are exaclty the same, otherwise they are discarded
  def intersect_filters(other)
    other_filters = other.instance_variable_get("@filters")
    new_filters = {}

    common_keys = @filters.keys & other_filters.keys

    common_keys.each do |k|
      next if @filters[k].nil? || other_filters[k].nil?

      new_value   = nil
      our_value   = @filters[k]
      their_value = other_filters[k]

      if our_value == their_value
        new_value = our_value
      elsif our_value.is_a?(Array) && their_value.is_a?(Array)
        new_value = our_value & their_value
      else
        if our_value.is_a? Array
          new_value = [their_value] if our_value.include?(their_value)
        elsif their_value.is_a? Array
          new_value = [our_value] if their_value.include?(our_value)
        end
      end

      new_filters[k] = new_value unless new_value.nil?
    end

    new_filters
  end

  # Returns the union of our filters and another set's filters
  # This alters keys in the following ways
  def union_filters(other)
    other_filters = other.instance_variable_get("@filters")
    new_filters   = {}

    all_keys = @filters.keys + other_filters.keys

    all_keys.each do |k|
      new_value   = nil
      our_value   = @filters[k]
      their_value = other_filters[k]

      if our_value == their_value
        new_value = our_value
      elsif our_value.is_a?(Array) && their_value.is_a?(Array)
        new_value = (our_value + their_value).uniq
      else
        new_value = [our_value, their_value].flatten.uniq
      end

      new_filters[k] = new_value
    end

    new_filters
  end

  # Filter our transaction set given our filters.
  def filter!
    dirpath = File.expand_path(__FILE__).sub(/\.rb$/, '')
    Dir.entries(dirpath).each do |filter|
      next if filter =~ /^\./
      next if filter == 'reference.rb' # special base class
      next if filter == 'enum.rb' # special base class

      filter_name = filter.sub(/\.rb$/, '')
      require "mny/transaction_set/#{ filter_name }"
      klass = "Mny::TransactionSet::#{ filter_name.classify }".constantize

      set = klass.new @filters
      if set.count > 0
        their_transactions = set.instance_variable_get('@transactions')

        if @transactions.nil? or @transactions.count == 0
          @transactions = their_transactions
        else
          @transactions.merge(their_transactions)
        end
      end
    end

    @reporter = Mny::Report.new(@transactions)
  end
end
