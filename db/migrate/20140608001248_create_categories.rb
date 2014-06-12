class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.references  :user, index: true
      t.integer     :parent_id
      t.string      :name
      t.integer     :transaction_type

      t.timestamps
    end

    add_index :categories, [:user_id, :name]
    add_index :categories, [:user_id, :transaction_type]
  end
end
