# Implements an Amount transaction set.
#
# Filter values:
#  - amount: If a single value, returns transactions that equal this amount.  If an array, uses the first value as the lowest value in a range, and the second value as the highest value.  Use nil to indicate greater / lesser than expressions, ie:
#    amount: 50 (amount == 50)
#    amount: nil, 50 (amount <= 50)
#    amount: 50, nil (amount >= 50)
#    amount: 25, 50 (amount >= 25 && amount <= 50)
class Mny::TransactionSet::Amount < Mny::TransactionSet

  def filter!
    return if @filtered or @filters[:amount].nil?

    min = nil
    max = nil
    val = nil

    if @filters[:amount].class == Array
      min = @filters[:amount][0]
      max = @filters[:amount][1]
    else
      val = @filters[:amount]
    end

    if min || max
      scope = Transaction

      scope = scope.where('amount >= ?', min) unless min.nil?
      scope = scope.where('amount <= ?', max) unless max.nil?

      @transactions = scope
    end

    unless val.nil?
      @transactions = Transaction.where('amount = ?', val)
    end

    @filtered = true
  end

end
