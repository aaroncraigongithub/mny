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

require 'rails_helper'
require 'mny_helper'

RSpec.describe Account, :type => :model do

  it 'only allows unique names' do
    name = 'thesame'
    create(:account, name: name)

    account = build(:account, name: name)
    expect(account.valid?).to eq false
    expect(account.errors.messages[:name].first).to eq "has already been taken"
  end

  context 'transactions' do
    let(:user)    { create(:user_with_account) }
    let(:account) { user.account }

    it "automatically creates a new category" do
      endpoint = create(:transaction_endpoint, user: user)
      category = build(:category).name

      account.deposit(50, from: endpoint, category: category)
      expect(user.categories.first.name).to eq(category)
    end

    it "automatically creates a new endpoint" do
      endpoint = build(:transaction_endpoint, user: user).name

      account.deposit(50, from: endpoint)
      expect(user.transaction_endpoints.first.name).to eq(endpoint)
    end
  end

  context 'reports' do
    context '.balance' do

      let(:account)   { create(:account) }
      let(:endpoint)  { create(:transaction_endpoint, user: account.user) }
      let(:amount)    { random_amount }

      it "knows it's balance" do
        account.deposit amount, from: endpoint
        expect(account.balance).to eq amount
      end

      it "knows it's negative balance" do
        account.withdraw amount, to: endpoint
        expect(account.balance).to eq amount * -1
      end

      it "knows it's balance on a given date" do
        balance = 0
        test_dt = nil

        (-5..5).each do |offset|
          t = Time.now + offset.days
          n = random_amount

          account.deposit n, from: endpoint, transaction_at: t

          if offset < 0
            balance += n
            test_dt = t
          end
        end

        expect(account.balance(test_dt)).to eq balance
      end
    end
  end
end
