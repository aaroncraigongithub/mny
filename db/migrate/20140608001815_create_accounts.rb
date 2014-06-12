class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.references  :user, index: true
      t.string      :name
      t.boolean     :is_default

      t.timestamps
    end
  end
end
