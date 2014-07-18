# == Schema Information
#
# Table name: transactions
#
#  id                      :integer          not null, primary key
#  user_id                 :integer
#  account_id              :integer
#  transaction_endpoint_id :integer
#  transfer_to             :integer
#  category_id             :integer
#  transaction_type        :string(255)
#  amount                  :integer
#  transaction_at          :datetime
#  status                  :string(255)
#  created_at              :datetime
#  updated_at              :datetime
#

require 'digest'

class Transaction < ActiveRecord::Base
  include TransactionSource

  validates :account, presence: true

  belongs_to :user
  belongs_to :account
  belongs_to :transferred_to,        class_name: 'Account', foreign_key: 'transfer_to'
  belongs_to :transferred_from,      class_name: 'Account', foreign_key: 'transfer_from'
  belongs_to :transaction_endpoint
  belongs_to :category

  enum transaction_type: [:deposit, :withdrawal, :transfer_out, :transfer_in]
  enum status: [:unknown, :reconciled, :cleared]

  before_save :update_fingerprint

  # Returns the amount as a positive or negative integer according to the
  # transaction type.
  def adjusted_amount
    m = (deposit? or transfer_in?) ? 1 : -1
    amount * m
  end

  # Create a fingerprint from the given data for a Transaction.
  # `data` must include:
  #   - transaction_at
  #   - account_id
  #   - transaction_type
  #   - amount
  #   - endpoint - a string which is the name of the transaction_endpoint
  def self.fingerprint(data)
    key = %i(
      transaction_at
      account_id
      transaction_type
      amount
      endpoint
    ).map { |f| data[f] }.join('')

    # Digest::SHA256.new.digest key
  end

  private

  # Generate a fingerprint for this transaction, based on the date,
  # endpoint and amount.
  def update_fingerprint
    data = self.attributes.merge({endpoint: transaction_endpoint.name})
    write_attribute(:fingerprint, Transaction.fingerprint(data))
  end
end
