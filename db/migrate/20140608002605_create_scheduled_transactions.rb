class CreateScheduledTransactions < ActiveRecord::Migration
  def change
    create_table :scheduled_transactions do |t|
      t.references  :user, index: true
      t.references  :account, index: true
      t.integer     :transfer_to
      t.datetime    :transaction_at
      t.text        :repeats
      t.integer     :amount
      t.integer     :transaction_type

      t.timestamps
    end

    add_index :scheduled_transactions, [:transaction_at]
    add_index :scheduled_transactions, [:transaction_type]
  end
end
