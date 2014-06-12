class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.references  :user, index: true
      t.references  :account, index: true
      t.references  :transaction_endpoint, index: true
      t.integer     :transfer_to
      t.integer     :transfer_from
      t.references  :category, index: true
      t.integer     :transaction_type
      t.integer     :amount
      t.datetime    :transaction_at
      t.integer     :status, default: 0
      t.string      :currency

      t.timestamps
    end

    add_index :transactions, [:transaction_type]
    add_index :transactions, [:status]
    add_index :transactions, [:transaction_at]
  end
end
