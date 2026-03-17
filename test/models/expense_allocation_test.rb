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
end
