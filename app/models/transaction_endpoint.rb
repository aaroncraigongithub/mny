# == Schema Information
#
# Table name: transaction_endpoints
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class TransactionEndpoint < ActiveRecord::Base
  validates :name, uniqueness: true
  belongs_to  :user
  has_many    :transactions
end
