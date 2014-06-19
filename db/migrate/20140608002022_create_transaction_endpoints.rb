class CreateTransactionEndpoints < ActiveRecord::Migration
  def change
    create_table :transaction_endpoints do |t|
      t.references  :user, index: true
      t.string      :name

      t.timestamps
    end

    add_index :transaction_endpoints, [:name]
  end
end
