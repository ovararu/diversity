require "test_helper"

class ExpenseAllocationTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Validations
  # ---------------------------------------------------------------------------

  test "is valid with all required attributes" do
    allocation = ExpenseAllocation.new(
      expense: expenses(:no_category_expense),
      card_top_up: card_top_ups(:other_top_up),
      amount: 25
    )
    assert allocation.valid?
  end

  test "is invalid without amount" do
    allocation = ExpenseAllocation.new(
      expense: expenses(:no_category_expense),
      card_top_up: card_top_ups(:other_top_up)
    )
    assert_not allocation.valid?
    assert_includes allocation.errors[:amount], "can't be blank"
  end

  test "is invalid when amount is zero" do
    allocation = ExpenseAllocation.new(
      expense: expenses(:no_category_expense),
      card_top_up: card_top_ups(:other_top_up),
      amount: 0
    )
    assert_not allocation.valid?
    assert_includes allocation.errors[:amount], "must be greater than 0"
  end

  test "is invalid when amount is negative" do
    allocation = ExpenseAllocation.new(
      expense: expenses(:no_category_expense),
      card_top_up: card_top_ups(:other_top_up),
      amount: -10
    )
    assert_not allocation.valid?
    assert_includes allocation.errors[:amount], "must be greater than 0"
  end

  test "is invalid without expense" do
    allocation = ExpenseAllocation.new(
      card_top_up: card_top_ups(:other_top_up),
      amount: 25
    )
    assert_not allocation.valid?
  end

  test "is invalid without card_top_up" do
    allocation = ExpenseAllocation.new(
      expense: expenses(:no_category_expense),
      amount: 25
    )
    assert_not allocation.valid?
  end

  # ---------------------------------------------------------------------------
  # Associations
  # ---------------------------------------------------------------------------

  test "belongs to expense" do
    allocation = expense_allocations(:food_allocation)
    assert_equal expenses(:food_expense), allocation.expense
  end

  test "belongs to card_top_up" do
    allocation = expense_allocations(:food_allocation)
    assert_equal card_top_ups(:salary_top_up), allocation.card_top_up
  end

  # ---------------------------------------------------------------------------
  # real_cost
  # ---------------------------------------------------------------------------

  test "real_cost scales allocation by gross/net ratio of the top-up" do
    # salary_top_up: net=5000, deductions=1918.75, gross=6918.75
    # food_allocation: amount=300 from salary_top_up
    # real_cost = 300 * 6918.75 / 5000 = 415.125 → 415.13
    allocation = expense_allocations(:food_allocation)
    expected = (300.0 * card_top_ups(:salary_top_up).gross_amount_computed / card_top_ups(:salary_top_up).net_amount).round(2)
    assert_equal expected, allocation.real_cost
  end

  test "real_cost equals amount when top-up has no deductions" do
    ExpenseAllocation.delete_all
    Expense.delete_all
    SourceDeduction.delete_all
    CardTopUp.delete_all

    top_up = CardTopUp.create!(date: Date.today, net_amount: 1000, source_type: "transfer")
    expense = Expense.create!(date: Date.today, description: "Test", amount: 200)
    alloc = expense.expense_allocations.find_by(card_top_up: top_up)
    assert_not_nil alloc, "Expected allocation to top_up"
    assert_equal 200.0, alloc.real_cost.to_f
  end
end
