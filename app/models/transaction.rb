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

class Transaction < ActiveRecord::Base
  belongs_to :user
  belongs_to :account
  belongs_to :transfered_to, class_name: 'Account', foreign_key: 'transfer_to'
  belongs_to :transaction_endpoint
  belongs_to :category

  enum transaction_type: [:deposit, :withdrawal, :transfer_out, :transfer_in]
  enum status: [:unknown, :reconciled, :cleared]

  # Returns the amount as a positive or negative integer according to the transaction type.
  def adjusted_amount
    m = (deposit? or transfer_in?) ? 1 : -1
    amount * m
  end
end
