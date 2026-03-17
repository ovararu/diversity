class CreateSourceDeductions < ActiveRecord::Migration[8.1]
  def change
    create_table :source_deductions do |t|
      t.references :card_top_up, null: false, foreign_key: true
      t.string :name
      t.decimal :amount, precision: 10, scale: 2
      t.decimal :percentage, precision: 5, scale: 2
      t.string :paid_by

      t.timestamps
    end
  end
end
