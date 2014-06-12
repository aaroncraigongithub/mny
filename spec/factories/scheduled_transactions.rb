# == Schema Information
#
# Table name: scheduled_transactions
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  account_id     :integer
#  transfer_to    :integer
#  transaction_at :datetime
#  repeats        :text
#  amount         :integer
#  type           :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :scheduled_transaction do
    user
    account
    transfer_to     nil
    transaction_at  { Time.new - rand(5).days }
    repeats         ""
    amount          { (rand(100) + 1) * 100 }
    type            'deposit'

    factory :transfer_scheduled_transaction do
      type 'transfer'

      after(:create) do |t, e|
        t.transfer_to = create(:account, user: t.user)
        t.save!
      end
    end
  end
end
