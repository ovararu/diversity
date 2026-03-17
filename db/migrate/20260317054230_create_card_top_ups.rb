class CreateCardTopUps < ActiveRecord::Migration[8.1]
  def change
    create_table :card_top_ups do |t|
      t.date :date
      t.string :description
      t.string :source_type
      t.decimal :net_amount, precision: 10, scale: 2
      t.decimal :gross_amount, precision: 10, scale: 2
      t.decimal :eur_rate, precision: 10, scale: 4

      t.timestamps
    end
  end
end
