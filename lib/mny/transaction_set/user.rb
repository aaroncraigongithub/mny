# Implements a User transaction set.
#
# Filter values (one of these must be present):
#  - user_id:   The user id to filter transactions for
#  - user:      A user instance
class Mny::TransactionSet::User < Mny::TransactionSet

  def filter!
    user_id = @filters[:user_id] || (@filters[:user].nil? ? nil : @filters[:user].id)
    @transactions = Transaction.where('user_id = ?', user_id) unless user_id.nil?
  end

end
