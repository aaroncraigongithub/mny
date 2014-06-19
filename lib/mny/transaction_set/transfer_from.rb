# Implements a TransferFrom transaction set.
#
# Filter values (one of these must be present):
#  - transfer_from_id:   One, or an array of, account ids
#  - transfer_from:   One, or an array of, account instances
require 'mny/transaction_set/reference'

class Mny::TransactionSet::TransferFrom < Mny::TransactionSet::Reference

  def initialize(filters = {})
    @id_key       = :transfer_from_id
    @ref_key      = :transfer_from
    @foreign_key  = @ref_key

    super
  end

end
