# Implements a TransactionType transaction set.
#
# Filter values (one of these must be present):
#  - transaction_type:   One, or an array of, transaction types
require 'mny/transaction_set/enum'

class Mny::TransactionSet::TransactionType < Mny::TransactionSet::Enum

  def initialize(filters = {})
    @enum_key = :transaction_type

    super
  end

end
