# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    email         { Faker::Internet.email }
    password      { Faker::Internet.password(8) }
    confirmed_at  { Date.today - 1.day }

    factory :user_with_account do
      after(:create) do |u, e|
        create(:account, user: u, is_default: true)
      end

      factory :user_with_two_accounts do
        after(:create) do |u, e|
          create(:account, user: u, is_default: false)
        end

        factory :user_with_two_accounts_and_transactions do
          after(:create) do |u, e|
            10.times do |i|
              d = Date.today - i.days
              create(:deposit, transaction_at: d, user: u, account: u.account)
            end

            5.times do |i|
              d = Date.today - i.days
              create(:withdrawal, transaction_at: d, user: u, account: u.account)
            end

            3.times do |i|
              d = Date.today - i.days
              create(:deposit, transaction_at: d, user: u, account: u.accounts.last)
            end
          end
        end
      end
    end
  end
end
