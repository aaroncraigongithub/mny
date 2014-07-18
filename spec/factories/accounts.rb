# == Schema Information
#
# Table name: accounts
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  name       :string(255)
#  is_default :boolean
#  created_at :datetime
#  updated_at :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :account do
    user
    name { "Bank of #{ Faker::Address.city } #{ Faker::Company.suffix }" }

    factory :positive_account do
      after(:create) do |a, e|
        5.times do
          create(:transaction, user: a.user, account: a)
        end
      end
    end
  end
end
