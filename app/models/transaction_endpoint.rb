# == Schema Information
#
# Table name: transaction_endpoints
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  label      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class TransactionEndpoint < ActiveRecord::Base
  validates :label, uniqueness: true
  belongs_to :user
end
