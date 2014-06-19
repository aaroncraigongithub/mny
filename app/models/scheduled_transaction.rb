class ScheduledTransaction < ActiveRecord::Base
  include TransactionSource

  belongs_to :user
  belongs_to :account
  belongs_to :transferred_to,        class_name: 'Account', foreign_key: 'transfer_to'
  belongs_to :transferred_from,      class_name: 'Account', foreign_key: 'transfer_from'
  belongs_to :transaction_endpoint
  belongs_to :category

  enum transaction_type: [:deposit, :withdrawal, :transfer_out, :transfer_in]
  serialize :schedule
end
