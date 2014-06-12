# == Schema Information
#
# Table name: categories
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  parent_id  :integer
#  name       :string(255)
#  type       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :category do
    name { Faker::Commerce.department }
    transaction_type 'deposit'

    factory :sub_category do
      after(:create) do |c, e|
        transaction_type = "#{ c.transaction_type }_category".to_s
        c.parent_id = create(type)
        c.save!
      end
    end
  end
end
