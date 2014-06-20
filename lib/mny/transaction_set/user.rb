# Implements a User transaction set.
#
# Filter values (one of these must be present):
#  - user_id:   The user id to filter transactions for
#  - user:      A user instance
class Mny::TransactionSet::User < Mny::TransactionSet

  def filter!
    return if @filters[:user_id].nil? && @filters[:user].nil?
    @active = true

    user_id = @filters[:user_id] || (@filters[:user].nil? ? nil : @filters[:user].id)
    @transactions = Transaction.where('user_id = ?', user_id) unless user_id.nil?
  end

end
