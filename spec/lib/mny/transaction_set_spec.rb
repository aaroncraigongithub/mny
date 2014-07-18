require 'rails_helper'
require 'mny_helper'

describe Mny::TransactionSet do

  # Create some test data.  Real test data.  For actual tests.  No mocks needed or desired.
  before(:all) do
    User.destroy_all

    user = create(:user_with_account)

    test_cats = {
      dep_1: create(:category, user: user, transaction_type: :deposit),
      dep_2: create(:category, user: user, transaction_type: :deposit),
      wit_1: create(:category, user: user, transaction_type: :withdrawal),
      wit_2: create(:category, user: user, transaction_type: :withdrawal)
    }.with_indifferent_access

    test_ends = {
      dep_1: create(:transaction_endpoint, user: user),
      dep_2: create(:transaction_endpoint, user: user),
      wit_1: create(:transaction_endpoint, user: user),
      wit_2: create(:transaction_endpoint, user: user)
    }.with_indifferent_access

    amounts = [
      25,
      10,
      45,
      10,
      10,
      5
    ]

    (-5..5).each do |offset|
      date = Time.now.getutc + offset.days

      # Balances:
      # -5: 5     (0+5)
      # -4: 15    (5+10)
      # -3: 25    (15+10)
      # -2 -20    (25+-45)
      # -1: -10   (-20+10)
      # 0: 15     (-10+25)
      # *: -30    (15+-45) transfer_out happens after this block
      # 1: -20    (-30+10)
      # 2: 25     (-20+45)
      # 3: 15     (15+-10)
      # 4: 5      (15+-10)
      # 5: 0      (5+-5)

      amount = amounts[offset.abs] # 0 index seen once, everyone else seen twice
      operation = (offset == -2 or offset > 2) ? :withdraw : :deposit
      # puts "#{ date } (#{ offset }): #{ operation } - #{ amount }"

      switch = (offset.abs % 2 == 0)? 1 : 2

      # Categories
      # -5: deposit/odd:    dep_2
      # -4: deposit/even:   dep_1
      # -3: deposit/odd:    dep_2
      # -2: withdraw/even:  wit_1
      # -1: deposit/odd:    dep_2
      # 0:  deposit/even:   dep_1
      # 1:  deposit/odd:    dep_2
      # 2:  deposit/even:   dep_1
      # 3:  withdraw/odd:   wit_2
      # 4:  withdraw/even:  wit_1
      # 5:  withdraw/odd:   wit_2

      category = (operation == :deposit) ? test_cats["dep_#{ switch }"] : test_cats["wit_#{ switch }"]

      # Source
      # -5: to: account     from: dep_2
      # -4: to: account     from: dep_1
      # -3: to: account     from: dep_2
      # -2: to: wit_1       from: account
      # -1: to: account     from: dep_2
      # 0:  to: account     from: dep_1
      # 1:  to: account     from: dep_2
      # 2:  to: account     from: dep_1
      # 3:  to: wit_2       from: account
      # 4:  to: wit_1       from: account
      # 5:  to: wit_2       from: account

      to = nil
      from = nil
      if operation == :deposit
        to = user.account
        from = test_ends["dep_#{ switch }"]
      else
        to = test_ends["wit_#{ switch }"]
        from = user.account
      end

      #Status
      # -5: odd:   cleared
      # -4: even:  reconciled
      # -3: odd:   cleared
      # -2: even:  reconciled
      # -1: odd:   cleared
      # 0:  even:  unknown
      # 1:  odd:   cleared
      # 2:  even:  reconciled
      # 3:  odd:   cleared
      # 4:  even:  reconciled
      # 5:  odd:   cleared

      status = (offset == 0) ? :unknown : (switch == 1 ? :reconciled : :cleared)
      user.send(operation, amount, {category: category, transaction_at: date, to: to, from: from, status: status})
    end

    # Create a second account to test the account filter
    account = create(:account, user: user, name: "Second account")
    endpoint = create(:transaction_endpoint, user: user)
    user.deposit(15, {to: account, from: endpoint})

    user.transfer(45, to: account)
  end

  context 'API' do

    let(:user)              { User.first }
    let(:ref_time)          { Time.now.getutc }
    let(:transaction_set)   { user.transaction_set }
    let(:before_set)        { user.transaction_set(transacted_before: ref_time) }
    let(:after_set)         { user.transaction_set(transacted_after: ref_time) }
    let(:date_range_set)    { user.transaction_set(transacted_after: ref_time - 1.day, transacted_before: ref_time + 1.day) }
    let(:deposit_set)       { user.transaction_set(transaction_type: :deposit) }
    let(:known_status_set)  { user.transaction_set(status: [:reconciled, :cleared]) }

    context 'endpoints' do
      it "retrieves a transaction set" do
        expect(transaction_set).to be_a_kind_of Mny::TransactionSet
      end

      it "iterates the set" do
        transaction_set.each do |t|
          expect(t).to be_a_kind_of Transaction
        end
      end

      it "retrieves the end date of the range" do
        expect(before_set.end_date.to_date).to eq (ref_time).to_date
      end

      it "retrieves the start date of the range" do
        expect(after_set.start_date.to_date).to eq (ref_time).to_date
      end

      it "retrieves the accounts in the range" do
        expect(transaction_set.accounts.collect(&:id).sort).to eq(user.accounts.collect(&:id).sort)
      end

      it "retrieves the transaction endpoints in the range" do
       expect(transaction_set.transaction_endpoints.collect(&:id).sort).to eq(user.transaction_endpoints.collect(&:id).sort)
      end

      it "retrieves the categories in the range" do
        expect(transaction_set.categories.collect(&:id).sort).to eq(user.categories.collect(&:id).sort)
      end

      it "retrieves the transaction types in the range" do
        expect(deposit_set.transaction_types).to eq(['deposit'])
      end

      it "retrieves the transaction status in the range" do
        expect(known_status_set.status.sort).to eq(['cleared', 'reconciled'])
      end

      context '.report' do
        it "generates a report" do
          data  = transaction_set.report
          i     = 0

          reporter = transaction_set.instance_variable_get('@reporter')
          reporter.send(:sorted_transactions).each do |t|
            cat_name = t.category.nil? ? 'Uncategorized' : t.category.name

            expect(data[i][:id]).to eq t.id
            expect(data[i][:category]).to eq cat_name
            expect(data[i][:status]).to eq t.status
            expect(data[i][:from]).to eq t.from.name

            i += 1
          end
        end

        it "calculates the amount in for a set" do
          expect(transaction_set.amount_in).to eq 175
        end

        it "calculates the amount out for a set" do
          expect(transaction_set.amount_out).to eq 115
        end
      end

      context "totals" do

        let(:account_set) { user.transaction_set(account: user.account) }

        it "retrieves the final balance of the range" do
          expect(account_set.balance).to eq 0
        end

        it "retrieves the balance at a specified date" do
          t = Time.now.getutc - 3.days
          expect(account_set.balance(t)).to eq 25
        end

        it "retrieves the total variation of the range" do
          expect(account_set.variation).to eq 55
        end

        it "retrieves the highest total for the range" do
          expect(account_set.high).to eq 25
        end

        it "retrieves the lowest total for the range" do
          expect(account_set.low).to eq(-30)
        end

        it "reveals if the total is ever below zero" do
          expect(account_set.negative_balances.values.sort).to eq [-30, -20, -20, -10].sort
          expect(account_set.negative_balances.keys.sort).to eq [(Time.now.getutc - 1.day).to_date, Time.now.getutc.to_date, (Time.now.getutc + 1.day).to_date, (Time.now.getutc + 2.days).to_date].sort
        end
      end
    end

    context 'filters' do

      it "filters by user" do
        transaction_set.each do |t|
          expect(t.user_id).to eq user.id
        end
      end

      it "filters by a start date" do
        after_set.each do |t|
          expect(t.transaction_at.to_date).to be >= ref_time.to_date
        end
      end

      it "filters by an end date" do
        before_set.each do |t|
          expect(t.transaction_at.to_date).to be <= ref_time.to_date
        end
      end

      it "filters by a date range" do
        date_range_set.each do |t|
          expect(t.transaction_at.to_date).to be <= (ref_time + 1.day).to_date
          expect(t.transaction_at.to_date).to be >= (ref_time - 1.day).to_date
        end
      end

      it "filters by account" do
        account = user.account("Second account")
        set = user.transaction_set(account: account)
        set.each do |transaction|
          expect(transaction.account_id).to eq account.id
        end
      end

      it "filters by transaction endpoint" do
        te = user.transaction_endpoints.first
        set = user.transaction_set(transaction_endpoint_id: te.id)

        expect(set.count).not_to eq 0
        set.each do |transaction|
          expect(transaction.transaction_endpoint_id).to eq te.id
        end
      end

      it "filters by an array of transaction endpoints" do
        te1 = user.transaction_endpoints.first
        te2 = user.transaction_endpoints.last
        set = user.transaction_set(transaction_endpoint: [te1, te2])

        expect(set.count).not_to eq 0
        set.each do |transaction|
          expect([te1.id, te2.id]).to include(transaction.transaction_endpoint_id)
        end
      end

      it "filters by a transfer to account" do
        account = user.account("Second account")
        set = user.transaction_set(transfer_to: [account])

        expect(set.count).not_to eq 0
        set.each do |transaction|
          expect(transaction.transferred_to.id).to eq account.id
        end
      end

      it "filters by a transfer from account" do
        account = user.account
        set = user.transaction_set(transfer_from_id: account.id)

        expect(set.count).not_to eq 0
        set.each do |transaction|
          expect(transaction.transferred_from.id).to eq account.id
        end
      end

      it "filters by category" do
        category = user.categories.first
        set = user.transaction_set(category: category)

        expect(set.count).not_to eq 0
        set.each do |transaction|
          expect(transaction.category.id).to eq category.id
        end
      end

      it "filters by transaction type" do
        set = user.transaction_set(transaction_type: :deposit)

        expect(set.count).not_to eq 0
        set.each do |transaction|
          expect(transaction.deposit?).to be true
        end
      end

      it "filters by an array of transaction types" do
        set = user.transaction_set(transaction_type: [:withdrawal, :deposit])

        expect(set.count).not_to eq 0
        set.each do |transaction|
          expect(['withdrawal', 'deposit']).to include(transaction.transaction_type)
        end
      end

      it "filters by status" do
        set = user.transaction_set(status: :cleared)

        expect(set.count).not_to eq 0
        set.each do |transaction|
          expect(transaction.cleared?).to be true
        end
      end

      it "filters by an array of status" do
        set = user.transaction_set(status: [:cleared, :reconciled])

        expect(set.count).not_to eq 0
        set.each do |transaction|
          expect(['cleared', 'reconciled']).to include(transaction.status)
        end
      end

      it "gets an empty set for unmatched but present filters" do
        set = user.transaction_set(transacted_before: Time.now.getutc - 10.days)
        expect(set.count).to eq 0
      end
    end

    context "amount" do

      let(:sorted_transactions) { Transaction.where(user_id: user.id).order(:amount) }

      it "filters by an amount" do
        t = sorted_transactions[1]
        set = user.transaction_set(amount: t.amount)

        expect(set.count).not_to eq 0
        set.each do |transaction|
          expect(transaction.amount).to eq t.amount
        end
      end

      it "filters by a max amount" do
        t = sorted_transactions[1]
        set = user.transaction_set(amount: [nil, t.amount])

        expect(set.count).not_to eq 0
        set.each do |transaction|
          expect(transaction.amount).to be <= t.amount
        end
      end

      it "filters by a min amount" do
        t = sorted_transactions[sorted_transactions.count - 2]
        set = user.transaction_set(amount: [t.amount, nil])

        expect(set.count).not_to eq 0
        set.each do |transaction|
          expect(transaction.amount).to be >= t.amount
        end
      end

      it "filters by an amount range" do
        t1 = sorted_transactions.first
        t2 = sorted_transactions[2]
        set = user.transaction_set(amount: [t1.amount, t2.amount])

        expect(set.count).not_to eq 0
        set.each do |transaction|
          expect(transaction.amount).to be >= t1.amount
          expect(transaction.amount).to be <= t2.amount
        end
      end
    end

    context 'merged sets' do

        let(:cat1)          { user.categories.first }
        let(:cat2)          { user.categories.second }
        let(:set1)          { user.transaction_set(category: cat1) }
        let(:set2)          { user.transaction_set(category: [cat1, cat2]) }
        let(:intersection)  { set1 & set2 }
        let(:union)         { set1 + set2 }

      it "creates an intersection of two sets" do
        intersecting = []
        set1.each do |t1|
          set2.each do |t2|
            if t1.id == t2.id
              intersecting<< t1
              break
            end
          end
        end

        expect((intersection).count).to eq intersecting.count
      end

      it "creates an intersection of two set's filters" do
        filters = intersection.instance_variable_get('@filters')
        expect(filters[:category]).to eq [cat1]
      end

      it "creates a union of two sets" do
        unioning = []
        set1.each do |t1|
          unioning<< t1
        end

        set2.each do |t2|
          unioning<< t2 unless unioning.include?(t2)
        end

        expect(union.count).to eq unioning.count
      end

      it "creates a union of two set's filters" do
        filters = union.instance_variable_get('@filters')
        expect(filters[:category].sort).to eq [cat1, cat2].sort
      end
    end
  end
end

