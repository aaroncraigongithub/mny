# == Schema Information
#
# Table name: scheduled_transactions
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  account_id        :integer
#  transfer_to       :integer
#  transaction_at    :datetime
#  repeats           :text
#  amount            :integer
#  transaction_type  :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#

class ScheduledTransaction < ActiveRecord::Base
  belongs_to :user
  belongs_to :account

  enum transaction_type: [:deposit, :withdrawal, :transfer]
end
