require 'rails_helper'
require 'mny_helper'

describe Mny::Forecast do
  context '.forecast' do

    before(:all) do
      User.destroy_all

      user      = create(:user_with_account)
      endpoint  = create(:transaction_endpoint, user: user)

      [10, 25, 30].each do |amount|
        user.will_deposit amount, from: endpoint, on: Time.now + amount.days
      end

      dep_s = IceCube::Schedule.new do |s|
        s.add_recurrence_rule(IceCube::Rule.daily(2))
      end
      user.will_deposit(25, from: endpoint, schedule: dep_s)

      wit_s = IceCube::Schedule.new do |s|
        s.add_recurrence_rule(IceCube::Rule.daily(2))
      end
      user.will_withdraw(10, to: endpoint, schedule: wit_s)

      user.will_withdraw(180, to: endpoint, on: Time.now + 20.days)

      # Balances
      # 0:    0    19
      # 1:    0    20
      # 2:    15   21
      # 3:    15   22
      # 4:    30   23
      # 5:    30   24
      # 6:    45   25
      # 7:    45   26
      # 8:    60   27
      # 9:    60   28
      # 10:   85   29
      # 11:   85   30
      # 12:   100  1
      # 13:   100  2
      # 14:   115  3
      # 15:   115  4
      # 16:   130  5
      # 17:   130  6
      # 18:   145  7
      # 19:   145  8
      # 20:   -20  9
      # 21:   -20  10
      # 22:   -5   11
      # 23:   -5   12
      # 24:   10   13
      # 25:   35   14
      # 26:   50   15
      # 27:   50   16
      # 28:   65   17
      # 29:   65   18
      # 30:   110  19
    end

    let(:forecast) { User.first.forecast }

    it "generates a forecast report" do
      expect(forecast.report).to be_a_kind_of Array
    end

    it "forecasts the final total" do
      expect(forecast.balance).to eq(110)
    end

    it "forecasts a midpoint total" do
      expect(forecast.balance(Time.now + 12.days)).to eq 100
    end

    it "forecasts 30 days by default" do
      expect(forecast.end_date.to_date).to eq (Time.now + 30.days).to_date
    end

    it "forecasts an arbitrary amount of days" do
      5.times do |i|
        offset = rand(100) + 1
        expect(User.first.forecast(days: offset).end_date.to_date).to eq (Time.now + offset.days).to_date
      end
    end

    it "reports negative amounts during the period" do
      n = forecast.negative_balances
      expect(n).to be_a_kind_of Hash
      expect(n.values.uniq.sort).to eq [-20, -5]
      expect(n.keys.sort).to eq [(Time.now + 20.days).to_date, (Time.now + 21.days).to_date, (Time.now + 22.days).to_date, (Time.now + 23.days).to_date]
    end

    it "reports the total variation of the range" do
      expect(forecast.variation).to eq 165
    end

    it "reports the highest total for the range" do
      expect(forecast.high).to eq 145
    end

    it "reports the lowest total for the range" do
      expect(forecast.low).to eq(-20)
    end
  end

  context "specials" do

    let(:user)      { create(:user_with_account) }
    let(:endpoint)  { create(:transaction_endpoint, user: user) }

    it "increments from the current net worth" do
      user.deposit(1000, from: endpoint)
      user.will_withdraw(900, to: endpoint, on: Time.now + 1.days)

      forecast = user.forecast(days: 2)
      expect(forecast.balance).to eq 100
    end

    it "doesn't count transactions until after their start date" do
      user.deposit(1000, from: endpoint)
      schedule = IceCube::Schedule.new do |s|
        s.add_recurrence_rule IceCube::Rule.daily
      end

      user.will_withdraw(900, to: endpoint, schedule: schedule, transaction_at: Time.now + 10.days)

      forecast = user.forecast(days: 2)
      expect(forecast.balance).to eq 1000
    end

    it "forecasts with an arbitrary starting balance" do
      user.deposit(1000, from: endpoint)
      user.will_withdraw(900, to: endpoint, on: Time.now + 1.days)

      forecast = user.forecast({days: 2, start_balance: 900})
      expect(forecast.balance).to eq(0)
    end
  end
end
