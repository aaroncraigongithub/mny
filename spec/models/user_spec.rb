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

require 'rails_helper'
require 'mny_helper'

RSpec.describe User, :type => :model do

  describe 'Accounts' do
    let(:user)      { create(:user) }

    it 'retrieves the only account as the default account' do
      account = create(:account, user: user)

      expect(user.account).to be_a_kind_of Account
      expect(user.account.name).to eq account.name
    end

    it 'retrieves the flagged account as the default account' do
      account = create(:account, user: user, is_default: true)
      create(:account, user: user)

      expect(user.account).to be_a_kind_of Account
      expect(user.account.name).to eq account.name
    end

    it 'retrieves an account by name' do
      create(:account, user: user, is_default: true)
      account = create(:account, user: user)

      expect(user.account(account.name)).to be_a_kind_of Account
      expect(user.account(account.name).name).to eq account.name
    end

    it 'retrieves the default account when specified' do
      account = create(:account, user: user, is_default: true)

      expect(user.account(:default)).to be_a_kind_of Account
      expect(user.account(:default).name).to eq account.name
    end
  end

  describe 'Transactions' do

    let(:user)      { create(:user_with_account) }
    let(:endpoint)  { create(:transaction_endpoint, user: user) }

    context 'deposits' do

      let(:amount)    { random_amount }

      it 'makes a deposit to the default account' do
        expect(user.deposit(amount, from: endpoint)).to be_a_kind_of Transaction
      end

      it 'makes a deposit in USD to the default account' do
        expect(user.deposit(amount, 'usd', from: endpoint)).to be_a_kind_of Transaction
      end

      it 'automatically creates a transaction_endpoint' do
        name = Faker::Company.name

        t = user.deposit(amount, 'usd', from: name)
        expect(t).to be_a_kind_of Transaction
        expect(t.transaction_endpoint.name).to eq name
      end

      it 'correctly sets the transaction type' do
        t = user.deposit(amount, from: endpoint)
        expect(t.transaction_type).to eq 'deposit'
        expect(t.deposit?).to eq true
      end

      it 'adjusts the user balance' do
        pre = user.balance
        user.deposit amount, from: endpoint
        user.reload
        expect(user.balance).to eq pre + amount
      end

      it 'makes a deposit to a named account' do
        account = user.accounts.first
        pre     = account.balance

        user.deposit amount, to: account.name, from: endpoint
        user.reload
        account.reload

        expect(account.balance).to eq pre + amount
      end

      it 'makes a deposit to an account instance' do
        account = user.accounts.first
        pre     = account.balance

        user.deposit amount, to: account, from: endpoint
        user.reload
        account.reload

        expect(account.balance).to eq pre + amount
      end
    end

    context 'withdrawals' do

      let(:amount) { random_amount * -1 }

      it 'makes a withdrawal from the default account' do
        expect(user.withdraw(amount, to: endpoint)).to be_a_kind_of Transaction
      end

      it 'makes a deposit in USD to the default account' do
        expect(user.withdraw(amount, 'usd', to: endpoint)).to be_a_kind_of Transaction
      end

      it 'automatically creates a transaction_endpoint' do
        name = Faker::Company.name

        t = user.withdraw(amount, 'usd', to: name)
        expect(t).to be_a_kind_of Transaction
        expect(t.transaction_endpoint.name).to eq name
      end

      it 'correctly sets the transaction type' do
        t = user.withdraw(amount, to: endpoint)
        expect(t.transaction_type).to eq 'withdrawal'
        expect(t.withdrawal?).to eq true
      end

      it 'adjusts the user balance' do
        pre = user.balance
        user.withdraw amount, to: endpoint
        user.reload
        user.accounts.first.reload

        expect(user.balance).to eq pre + (amount * -1)
      end

      it 'withdraws from a named account' do
        account = user.accounts.first
        pre     = account.balance

        user.withdraw amount, from: account.name, to: endpoint
        user.reload
        account.reload

        expect(account.balance).to eq pre + (amount * -1)
      end

      it 'withdraws from an account instance' do
        account = user.accounts.first
        pre     = account.balance

        user.withdraw amount, from: account, to: endpoint
        user.reload
        account.reload

        expect(account.balance).to eq pre + (amount * -1)
      end
    end

    context 'transfers' do

      let(:amount)        { random_amount }
      let(:other_account) { create(:account, user: user) }
      let(:endpoint)      { create(:transaction_endpoint, user: user) }

      before(:each) do
        user.deposit amount, from: endpoint
        user.reload
      end

      it 'transfers from one account to another' do
        expect(user.transfer amount, to: other_account).to be_a_kind_of Transaction
      end

      it 'transfers EUR from one account to another' do
        expect(user.transfer amount, 'eur', to: other_account).to be_a_kind_of Transaction
      end

      it 'transfers from a named account' do
        expect(user.transfer amount, from: user.accounts.first.name, to: other_account).to be_a_kind_of Transaction
      end

      it 'transfers from an account instance' do
        expect(user.transfer amount, from: user.accounts.first, to: other_account).to be_a_kind_of Transaction
      end

      it 'transfers to a named account' do
        expect(user.transfer amount, to: other_account.name).to be_a_kind_of Transaction
      end

      it 'maintains the user balance' do
        pre = user.balance
        user.transfer amount, to: other_account

        expect(User.find(user.id).balance).to eq pre
      end

      it 'adjusts the from account balance' do
        account = user.accounts.first
        pre     = account.balance

        user.transfer amount, from: account, to: other_account
        user.reload
        account.reload

        expect(account.balance).to eq pre + (amount * -1)
      end

      it 'adjusts the to account balance' do
        pre     = other_account.balance

        user.transfer amount, to: other_account
        user.reload
        other_account.reload

        expect(other_account.balance).to eq pre + amount
      end
    end
  end

  context "schedules" do
    let(:user)      { create(:user_with_account) }
    let(:amount)    { random_amount }
    let(:endpoint)  { create(:transaction_endpoint, user: user) }
    let(:schedule)  {
      IceCube::Schedule.new do |s|
        s.add_recurrence_rule(IceCube::Rule.monthly.day_of_month(15))
      end
    }

    it 'schedules a one off deposit' do
      user.will_deposit(amount, from: endpoint, on: Time.now + 10.days)
      expect(user.scheduled_transactions.last.amount).to eq amount
      expect(user.scheduled_transactions.last.deposit?).to be true
    end

    it 'schedules a recurring deposit'do
      user.will_deposit(amount, from: endpoint, schedule: schedule)
      expect(user.scheduled_transactions.last.schedule.to_yaml).to eq schedule.to_yaml
    end

    it 'schedules a one off withdrawal' do
      user.will_withdraw(amount, to: endpoint, on: Time.now + 10.days)
      expect(user.scheduled_transactions.last.amount).to eq amount
      expect(user.scheduled_transactions.last.withdrawal?).to be true
    end

    it 'schedules a recurring withdrawal'do
      user.will_withdraw(amount, to: endpoint, schedule: schedule)
      expect(user.scheduled_transactions.last.schedule.to_yaml).to eq schedule.to_yaml
    end

    it 'schedules a one off transfer' do
      account = create(:account, user: account)
      user.will_transfer(amount, to: account, on: Time.now + 10.days)
      expect(user.scheduled_transactions.last.amount).to eq amount
    end

    it 'schedules a recurring withdrawal'do
      account = create(:account, user: account)
      user.will_transfer(amount, to: account, schedule: schedule)
      expect(user.scheduled_transactions.last.schedule.to_yaml).to eq schedule.to_yaml
    end
  end

  context 'reports' do

    let(:user)      { create(:user_with_account) }
    let(:amount)    { random_amount }
    let(:endpoint)  { create(:transaction_endpoint, user: user) }
    let(:category)  { Faker::Commerce.department }

    context '.balance' do
      it 'knows the current balance with one account' do
        user.deposit(amount, to: :default, from: endpoint )
        expect(user.balance).to eq amount
      end

      it 'knows the current balance with multiple accounts' do
        user = create(:user)

        total = 0
        3.times do
          this_amount = random_amount
          account = create(:account, user: user)

          user.deposit this_amount, to: account, from: endpoint
          total += this_amount
        end

        expect(user.balance).to eq total
      end

      it 'knows the balance from a given day' do
        balance = 0
        dt      = nil
        (-5..5).each do |offset|
          t = Time.now + offset.days
          n = random_amount

          user.deposit n, from: endpoint, transaction_at: t

          if offset < -2
            balance += n
            dt = t
          end
        end

        expect(user.balance(dt)).to eq balance
      end
    end

    context ''
  end
end
