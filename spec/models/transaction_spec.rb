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

require 'rails_helper'
require 'mny_helper'

RSpec.describe Transaction, :type => :model do

  context 'adjusted amount' do

    let(:amount) { random_amount }

    it 'correctly adjusts a deposit amount' do
      t = create(:deposit, amount: amount)
      expect(t.adjusted_amount).to eq amount
    end

    it 'correctly adjusts a withdrawal amount' do
      t = create(:withdrawal, amount: amount)
      expect(t.adjusted_amount).to eq amount * -1
    end

    it 'correctly adjusts a transfer in amount' do
      t = create(:transfer_in, amount: amount)
      expect(t.adjusted_amount).to eq amount
    end

    it 'correctly adjusts a transfer out amount' do
      t = create(:transfer_out, amount: amount)
      expect(t.adjusted_amount).to eq amount * -1
    end
  end

  context '.from' do
    it "returns the source of a withdrawal" do
      t = create(:withdrawal)
      expect(t.from).to be_a_kind_of Account
      expect(t.from.name).to eq t.account.name
    end

    it "returns the source of a deposit" do
      t = create(:deposit)
      expect(t.from).to be_a_kind_of TransactionEndpoint
      expect(t.from.name).to eq t.transaction_endpoint.name
    end

    it "returns the source of a transfer in" do
      t = create(:transfer_in)
      expect(t.from).to be_a_kind_of Account
      expect(t.from.name).to eq t.transferred_from.name
    end

    it "returns the source of a transfer out" do
      t = create(:transfer_out)
      expect(t.from).to be_a_kind_of Account
      expect(t.from.name).to eq t.account.name
    end
  end

  context '.from=' do

    let(:user)      { create(:user_with_account) }
    let(:account)   { create(:account, user: user) }
    let(:endpoint)  { create(:transaction_endpoint, user: user) }

    it "sets the source of a withdrawal" do
      t = create(:withdrawal)
      expect(t.account.id).not_to eq account.id

      t.from = account
      t.save!

      expect(t.account.id).to eq account.id
    end

    it "sets the source of a deposit" do
      t = create(:deposit)
      expect(t.transaction_endpoint.id).not_to eq endpoint.id

      t.from = endpoint
      t.save!

      expect(t.transaction_endpoint.id).to eq endpoint.id
    end

    it "sets the source of a transfer in" do
      t = create(:transfer_in)
      expect(t.transferred_from.id).not_to eq account.id

      t.from = account
      t.save!

      expect(t.transferred_from.id).to eq account.id
    end

    it "sets the source of a transfer out" do
      t = create(:transfer_out)
      expect(t.account.id).not_to eq account.id

      t.from = account
      t.save!

      expect(t.account.id).to eq account.id
    end
  end

  context '.to' do
    it "returns the recipient of a withdrawal" do
      t = create(:withdrawal)
      expect(t.to).to be_a_kind_of TransactionEndpoint
      expect(t.to.name).to eq t.transaction_endpoint.name
    end

    it "returns the recipient of a deposit" do
      t = create(:deposit)
      expect(t.to).to be_a_kind_of Account
      expect(t.to.name).to eq t.account.name
    end

    it "returns the recipient of a transfer in" do
      t = create(:transfer_in)
      expect(t.to).to be_a_kind_of Account
      expect(t.to.name).to eq t.account.name
    end

    it "returns the recipient of a transfer out" do
      t = create(:transfer_out)
      expect(t.to).to be_a_kind_of Account
      expect(t.to.name).to eq t.transferred_to.name
    end
  end

  context '.to=' do

    let(:user)      { create(:user_with_account) }
    let(:account)   { create(:account, user: user) }
    let(:endpoint)  { create(:transaction_endpoint, user: user) }

    it "sets the recipient of a withdrawal" do
      t = create(:withdrawal)
      expect(t.transaction_endpoint.id).not_to eq endpoint.id

      t.to = endpoint
      t.save!

      expect(t.transaction_endpoint.id).to eq endpoint.id
    end

    it "sets the recipient of a deposit" do
      t = create(:deposit)
      expect(t.account.id).not_to eq account.id

      t.to = account
      t.save!

      expect(t.account.id).to eq account.id
    end

    it "sets the recipient of a transfer in" do
      t = create(:transfer_in)
      expect(t.account.id).not_to eq account.id

      t.to = account
      t.save!

      expect(t.account.id).to eq account.id
    end

    it "sets the recipient of a transfer out" do
      t = create(:transfer_out)
      expect(t.transferred_to.id).not_to eq account.id

      t.to = account
      t.save!

      expect(t.transferred_to.id).to eq account.id
    end
  end
end
