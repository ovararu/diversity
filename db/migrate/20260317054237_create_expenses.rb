class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.date :date
      t.string :description
      t.decimal :amount, precision: 10, scale: 2
      t.string :category

      t.timestamps
    end
  end
end
