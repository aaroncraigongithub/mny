require 'rails_helper'

describe TransactionsController do

  describe 'GET /' do
    context "default filters" do
      it_behaves_like "a filtered transaction set", :user_with_two_accounts_and_transactions, {transacted_after: Time.now.getutc - 30.days}, {}
    end

    context "account filters" do
      it_behaves_like "a filtered transaction set", :user_with_two_accounts_and_transactions, {transacted_after: Time.now.getutc - 30.days, account: :other}, {account: :other}
    end

    context "date filters" do
      it_behaves_like "a filtered transaction set",
        :user_with_two_accounts_and_transactions,
        {
          transacted_after: Time.now.getutc - 4.days,
          transacted_before: Time.now.getutc - 2.days
        },
        {
          after: (Time.now.getutc - 4.days).strftime("%Y%m%d"),
          before: (Time.now.getutc - 2.days).strftime("%Y%m%d")
        }
    end

    context "transaction type filters" do
      it_behaves_like "a filtered transaction set",
        :user_with_two_accounts_and_transactions,
        {
          transaction_type: :deposit
        },
        {
          type: 'deposit'
        }
    end

    context "category filters" do
      it_behaves_like "a filtered transaction set",
        :user_with_two_accounts_and_transactions,
        {
          category: :any
        },
        {
          category: :any
        }
    end
  end
end
