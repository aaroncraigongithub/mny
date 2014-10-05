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
#  type                    :string(255)
#  amount                  :integer
#  transaction_at          :datetime
#  status                  :string(255)
#  created_at              :datetime
#  updated_at              :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :transaction do
    user
    account

    amount          { rand(100..10000) }
    transaction_at  { Time.new - rand(5).days }
    status          'cleared'

    factory :transfer_in do
      transaction_type 'transfer_in'

      after(:create) do |t, e|
        t.transferred_from = create(:account, user: t.user)
        t.save!
      end
    end
    factory :transfer_out do
      transaction_type 'transfer_out'

      after(:create) do |t, e|
        t.transferred_to = create(:account, user: t.user)
        t.save!
      end
    end

    factory :transaction_with_endpoint do
      transaction_endpoint

      factory :deposit do
        transaction_type 'deposit'
      end

      factory :withdrawal do
        transaction_type 'withdrawal'
      end
    end
  end
end
