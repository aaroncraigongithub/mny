class CreateScheduledTransactions < ActiveRecord::Migration
  def change
    create_table :scheduled_transactions do |t|
      t.references  :user, index: true
      t.references  :account, index: true
      t.references  :transaction_endpoint, index: true
      t.integer     :transfer_to
      t.integer     :transfer_from
      t.references  :category, index: true
      t.integer     :transaction_type
      t.integer     :amount
      t.datetime    :transaction_at
      t.text        :schedule
      t.string      :currency

      t.timestamps
    end

    add_index :scheduled_transactions, [:transaction_type]
    add_index :scheduled_transactions, [:transaction_at]
  end
end
