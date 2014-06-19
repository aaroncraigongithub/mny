# Implements a Status transaction set.
#
# Filter values (one of these must be present):
#  - status:   One, or an array of, status values
require 'mny/transaction_set/enum'

class Mny::TransactionSet::Status < Mny::TransactionSet::Enum

  def initialize(filters = {})
    @enum_key = :status

    super
  end

end
