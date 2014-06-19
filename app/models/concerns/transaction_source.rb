require 'active_support/concern'

module TransactionSource
  extend ActiveSupport::Concern

  # Returns the source of this transaction, depending on the transaction type:
  #   - deposit:      TransactionEndpoint (where the money came from)
  #   - withdrawal:   Account (this account)
  #   - transfer_in:  Account (where money came from)
  #   - transfer_out: Account (this account)
  def from
    return transaction_endpoint if deposit?
    return transferred_from if transfer_in?
    return account if withdrawal? or transfer_out?
  end

  # Sets the source of this transaction, according to the transaction type
  def from=(source)
    self.transaction_endpoint  = source.is_a?(TransactionEndpoint) ? source : TransactionEndpoint.find_or_create_by(user_id: user.id, name: source) if deposit?
    self.transferred_from      = source.is_a?(Account) ? source : user.account(source) if transfer_in?
    self.account               = source.is_a?(Account) ? source : user.account(source) if transfer_out? or withdrawal?
  end

  # Returns the recipient of this transaction, depending on the transaction type:
  #   - deposit:      Account (this account)
  #   - withdrawal:   TransactionEndpoint (where the money is going)
  #   - transfer_in:  Account (this account)
  #   - transfer_out: Account (where money is going)
  def to
    return transaction_endpoint if withdrawal?
    return transferred_to if transfer_out?
    return account if deposit? or transfer_in?
  end

  # Sets the recipient of this transaction, according to the transaction type
  def to=(source)
    self.transaction_endpoint  = source.is_a?(TransactionEndpoint) ? source : TransactionEndpoint.find_or_create_by(user_id: user.id, name: source) if withdrawal?
    self.transferred_to        = source.is_a?(Account) ? source : user.account(source) if transfer_out?
    self.account               = source.is_a?(Account) ? source : user.account(source) if transfer_in? or deposit?
  end

end
