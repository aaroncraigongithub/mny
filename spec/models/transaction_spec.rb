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
end
