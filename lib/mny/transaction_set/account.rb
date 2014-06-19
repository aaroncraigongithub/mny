# Implements an Account transaction set.
#
# Filter values (one of these must be present):
#  - account_id:   The account id to filter transactions for, or an array of them
#  - account:      An account instance, or an array of them

require 'mny/transaction_set/reference'

class Mny::TransactionSet::Account < Mny::TransactionSet::Reference

  def initialize(filters = {})
    @id_key       = :account_id
    @ref_key      = :account

    super
  end

end
