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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :transaction_endpoint do
    user
    label { Faker::Company.name }
  end
end
