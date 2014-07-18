class AddFingerprintToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :fingerprint, :string
  end
end
