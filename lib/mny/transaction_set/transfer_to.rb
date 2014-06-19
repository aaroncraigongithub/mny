# Implements a TransferTo transaction set.
#
# Filter values (one of these must be present):
#  - transfer_to_id:   One, or an array of, account ids
#  - transfer_to:   One, or an array of, account instances
require 'mny/transaction_set/reference'

class Mny::TransactionSet::TransferTo < Mny::TransactionSet::Reference

  def initialize(filters = {})
    @id_key       = :transfer_to_id
    @ref_key      = :transfer_to
    @foreign_key  = @ref_key

    super
  end

end
