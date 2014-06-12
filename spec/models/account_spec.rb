# == Schema Information
#
# Table name: accounts
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  name       :string(255)
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
