# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_17_054238) do
  create_table "card_top_ups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.string "description"
    t.decimal "eur_rate", precision: 10, scale: 4
    t.decimal "gross_amount", precision: 10, scale: 2
    t.decimal "net_amount", precision: 10, scale: 2
    t.string "source_type"
    t.datetime "updated_at", null: false
  end

  create_table "expense_allocations", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2
    t.integer "card_top_up_id", null: false
    t.datetime "created_at", null: false
    t.integer "expense_id", null: false
    t.datetime "updated_at", null: false
    t.index ["card_top_up_id"], name: "index_expense_allocations_on_card_top_up_id"
    t.index ["expense_id"], name: "index_expense_allocations_on_expense_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2
    t.string "category"
    t.datetime "created_at", null: false
    t.date "date"
    t.string "description"
    t.datetime "updated_at", null: false
  end

  create_table "source_deductions", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2
    t.integer "card_top_up_id", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.string "paid_by"
    t.decimal "percentage", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.index ["card_top_up_id"], name: "index_source_deductions_on_card_top_up_id"
  end

  add_foreign_key "expense_allocations", "card_top_ups"
  add_foreign_key "expense_allocations", "expenses"
  add_foreign_key "source_deductions", "card_top_ups"
end
