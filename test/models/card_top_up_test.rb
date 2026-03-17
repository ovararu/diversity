require "test_helper"

class CardTopUpTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Validations
  # ---------------------------------------------------------------------------

  test "is valid with all required attributes" do
    top_up = CardTopUp.new(date: Date.today, net_amount: 1000, source_type: "salary")
    assert top_up.valid?
  end

  test "is invalid without date" do
    top_up = CardTopUp.new(net_amount: 1000, source_type: "salary")
    assert_not top_up.valid?
    assert_includes top_up.errors[:date], "can't be blank"
  end

  test "is invalid without net_amount" do
    top_up = CardTopUp.new(date: Date.today, source_type: "salary")
    assert_not top_up.valid?
    assert_includes top_up.errors[:net_amount], "can't be blank"
  end

  test "is invalid without source_type" do
    top_up = CardTopUp.new(date: Date.today, net_amount: 1000)
    assert_not top_up.valid?
    assert_includes top_up.errors[:source_type], "can't be blank"
  end

  test "is invalid when net_amount is zero" do
    top_up = CardTopUp.new(date: Date.today, net_amount: 0, source_type: "transfer")
    assert_not top_up.valid?
    assert_includes top_up.errors[:net_amount], "must be greater than 0"
  end

  test "is invalid when net_amount is negative" do
    top_up = CardTopUp.new(date: Date.today, net_amount: -100, source_type: "transfer")
    assert_not top_up.valid?
    assert_includes top_up.errors[:net_amount], "must be greater than 0"
  end

  # ---------------------------------------------------------------------------
  # Associations
  # ---------------------------------------------------------------------------

  test "has many source_deductions" do
    top_up = card_top_ups(:salary_top_up)
    assert_equal 3, top_up.source_deductions.count
  end

  test "destroys source_deductions when destroyed" do
    top_up = card_top_ups(:salary_top_up)
    deduction_ids = top_up.source_deductions.pluck(:id)
    top_up.destroy
    deduction_ids.each do |id|
      assert_nil SourceDeduction.find_by(id: id)
    end
  end

  test "has many expense_allocations" do
    top_up = card_top_ups(:salary_top_up)
    assert_equal 2, top_up.expense_allocations.count
  end

  test "has many expenses through expense_allocations" do
    top_up = card_top_ups(:salary_top_up)
    assert_equal 2, top_up.expenses.count
  end

  # ---------------------------------------------------------------------------
  # total_deductions
  # ---------------------------------------------------------------------------

  test "total_deductions sums all source deduction amounts" do
    top_up = card_top_ups(:salary_top_up)
    # CAS 1250 + CASS 500 + CAM 168.75 = 1918.75
    assert_equal 1918.75, top_up.total_deductions.to_f
  end

  test "total_deductions returns 0 when there are no deductions" do
    top_up = card_top_ups(:transfer_top_up)
    assert_equal 0, top_up.total_deductions
  end

  # ---------------------------------------------------------------------------
  # gross_amount_computed
  # ---------------------------------------------------------------------------

  test "gross_amount_computed equals net_amount plus total_deductions" do
    top_up = card_top_ups(:salary_top_up)
    expected = top_up.net_amount + top_up.total_deductions
    assert_equal expected, top_up.gross_amount_computed
  end

  test "gross_amount_computed equals net_amount when there are no deductions" do
    top_up = card_top_ups(:transfer_top_up)
    assert_equal top_up.net_amount, top_up.gross_amount_computed
  end

  # ---------------------------------------------------------------------------
  # cost_ratio
  # ---------------------------------------------------------------------------

  test "cost_ratio returns percentage of deductions over gross" do
    top_up = card_top_ups(:salary_top_up)
    # gross = 5000 + 1918.75 = 6918.75, ratio = 1918.75 / 6918.75 * 100
    expected = (1918.75 / 6918.75 * 100).round(2)
    assert_equal expected, top_up.cost_ratio
  end

  test "cost_ratio returns 0 when there are no deductions" do
    top_up = card_top_ups(:transfer_top_up)
    assert_equal 0, top_up.cost_ratio
  end

  test "cost_ratio does not raise when net_amount equals total deductions edge case" do
    top_up = CardTopUp.new(date: Date.today, net_amount: 1000, source_type: "other")
    # No deductions, gross = net = 1000, cost_ratio = 0 / 1000 * 100 = 0
    assert_equal 0, top_up.cost_ratio
  end

  # ---------------------------------------------------------------------------
  # allocated_amount
  # ---------------------------------------------------------------------------

  test "allocated_amount sums all expense allocation amounts" do
    top_up = card_top_ups(:salary_top_up)
    # food 300 + transport 100 = 400
    assert_equal 400.0, top_up.allocated_amount.to_f
  end

  test "allocated_amount returns 0 when nothing has been allocated" do
    top_up = card_top_ups(:other_top_up)
    assert_equal 0, top_up.allocated_amount
  end

  # ---------------------------------------------------------------------------
  # remaining_balance
  # ---------------------------------------------------------------------------

  test "remaining_balance equals net_amount minus allocated_amount" do
    top_up = card_top_ups(:salary_top_up)
    # net 5000 - allocated 400 = 4600
    assert_equal 4600.0, top_up.remaining_balance.to_f
  end

  test "remaining_balance equals net_amount when nothing allocated" do
    top_up = card_top_ups(:other_top_up)
    assert_equal top_up.net_amount, top_up.remaining_balance
  end

  test "remaining_balance can be zero" do
    top_up = card_top_ups(:transfer_top_up)
    # transfer_top_up net=2000, no_category_allocation takes 50 → remaining=1950, not zero
    # Build a fully allocated top_up
    t = CardTopUp.create!(date: Date.today, net_amount: 100, source_type: "transfer")
    ExpenseAllocation.create!(
      card_top_up: t,
      expense: expenses(:food_expense),
      amount: 100
    )
    assert_equal 0, t.remaining_balance
  end

  # ---------------------------------------------------------------------------
  # eur_net
  # ---------------------------------------------------------------------------

  test "eur_net converts net_amount using eur_rate" do
    top_up = card_top_ups(:salary_top_up)
    # 5000 / 5.0 = 1000.0
    assert_equal 1000.0, top_up.eur_net
  end

  test "eur_net returns nil when eur_rate is nil" do
    top_up = card_top_ups(:no_eur_top_up)
    assert_nil top_up.eur_net
  end

  test "eur_net returns nil when eur_rate is zero" do
    top_up = CardTopUp.new(date: Date.today, net_amount: 1000, source_type: "transfer", eur_rate: 0)
    assert_nil top_up.eur_net
  end

  test "eur_net rounds to 2 decimal places" do
    top_up = card_top_ups(:transfer_top_up)
    # 2000 / 4.97 = 402.41...
    assert_equal (2000.0 / 4.97).round(2), top_up.eur_net
  end

  # ---------------------------------------------------------------------------
  # .ordered_by_cost_ratio
  # ---------------------------------------------------------------------------

  test "ordered_by_cost_ratio returns top-ups sorted descending by cost_ratio" do
    result = CardTopUp.ordered_by_cost_ratio
    ratios = result.map(&:cost_ratio)
    assert_equal ratios.sort.reverse, ratios
  end

  # ---------------------------------------------------------------------------
  # .with_remaining_balance
  # ---------------------------------------------------------------------------

  test "with_remaining_balance excludes top-ups with zero remaining balance" do
    fully_used = CardTopUp.create!(date: Date.today, net_amount: 50, source_type: "transfer")
    ExpenseAllocation.create!(
      card_top_up: fully_used,
      expense: expenses(:food_expense),
      amount: 50
    )
    assert_not_includes CardTopUp.with_remaining_balance, fully_used
  end

  test "with_remaining_balance includes top-ups with positive remaining balance" do
    top_up = card_top_ups(:other_top_up)
    assert_includes CardTopUp.with_remaining_balance, top_up
  end

  # ---------------------------------------------------------------------------
  # nested attributes for source_deductions
  # ---------------------------------------------------------------------------

  test "accepts nested attributes for source_deductions" do
    top_up = CardTopUp.create!(
      date: Date.today,
      net_amount: 4000,
      source_type: "salary",
      source_deductions_attributes: [
        { name: "CAS", amount: 1000, paid_by: "employee" },
        { name: "CASS", amount: 400, paid_by: "employee" }
      ]
    )
    assert_equal 2, top_up.source_deductions.count
    assert_equal 1400, top_up.total_deductions
  end

  test "rejects blank source_deduction nested attributes" do
    top_up = CardTopUp.create!(
      date: Date.today,
      net_amount: 4000,
      source_type: "salary",
      source_deductions_attributes: [{ name: "", amount: "" }]
    )
    assert_equal 0, top_up.source_deductions.count
  end
end
