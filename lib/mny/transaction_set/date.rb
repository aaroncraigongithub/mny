# Implements a Date transaction set.
#
# Filter values:
#  - transacted_after:   Only transactions occurring after this date will be included in the set.  If nil, all transactions before to_date will be included.
#  - transacted_before:     Only transactions occurring before this date will be included in the set.  If nil, all transactions after from_date will be included.
#
# If neither value is present, no transactions will be selected.

class Mny::TransactionSet::Date < Mny::TransactionSet

  def filter!
    after_date  = @filters[:transacted_after]
    before_date = @filters[:transacted_before]

    return if after_date.nil? && before_date.nil?

    raise "Date filters must be instances of Time" unless before_date.nil? || before_date.class == Time
    raise "Date filters must be instances of Time" unless before_date.nil? || before_date.class == Time

    start_scope = after_date ? ">= '#{ after_date.midnight }'" : "IS NOT NULL"
    end_scope   = before_date ? "<= '#{ before_date.end_of_day }'" : "IS NOT NULL"

    @transactions = Transaction.where("transaction_at #{ start_scope } AND transaction_at #{ end_scope }")
  end

end
