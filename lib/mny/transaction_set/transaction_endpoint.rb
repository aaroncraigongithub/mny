# Implements a TransactionEndpoint transaction set.
#
# Filter values (one of these must be present):
#  - transaction_endpoint_id:   One, or an array of, transaction endpoint ids
#  - transaction_endpoint:   One, or an array of, transaction endpoint instances
require 'mny/transaction_set/reference'

class Mny::TransactionSet::TransactionEndpoint < Mny::TransactionSet::Reference

  def initialize(filters = {})
    @id_key       = :transaction_endpoint_id
    @ref_key      = :transaction_endpoint

    super
  end

end
