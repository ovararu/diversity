class CreateExpenseAllocations < ActiveRecord::Migration[8.1]
  def change
    create_table :expense_allocations do |t|
      t.references :expense, null: false, foreign_key: true
      t.references :card_top_up, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2

      t.timestamps
    end
  end
end
