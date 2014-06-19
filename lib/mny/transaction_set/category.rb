# Implements a Category transaction set.
#
# Filter values (one of these must be present):
#  - transfer_to_id:   One, or an array of, account ids
#  - transfer_to:   One, or an array of, account instances
require 'mny/transaction_set/reference'

class Mny::TransactionSet::Category < Mny::TransactionSet::Reference

  def initialize(filters = {})
    @id_key       = :category_id
    @ref_key      = :category

    super
  end

end
