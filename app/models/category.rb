# == Schema Information
#
# Table name: categories
#
#  id                 :integer          not null, primary key
#  user_id            :integer
#  parent_id          :integer
#  name               :string(255)
#  transaction_type   :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#

class Category < ActiveRecord::Base
  belongs_to :category
  belongs_to :user
  has_many :transactions

  enum transaction_type: [:deposit, :withdrawal, :transfer]

end
