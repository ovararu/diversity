require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Validations
  # ---------------------------------------------------------------------------

  test "is valid with all required attributes" do
    expense = Expense.new(date: Date.today, description: "Coffee", amount: 15)
    assert expense.valid?
  end

  test "is invalid without date" do
    expense = Expense.new(description: "Coffee", amount: 15)
    assert_not expense.valid?
    assert_includes expense.errors[:date], "can't be blank"
  end

  test "is invalid without description" do
    expense = Expense.new(date: Date.today, amount: 15)
    assert_not expense.valid?
    assert_includes expense.errors[:description], "can't be blank"
  end

  test "is invalid without amount" do
    expense = Expense.new(date: Date.today, description: "Coffee")
    assert_not expense.valid?
    assert_includes expense.errors[:amount], "can't be blank"
  end

  test "is invalid when amount is zero" do
    expense = Expense.new(date: Date.today, description: "Coffee", amount: 0)
    assert_not expense.valid?
    assert_includes expense.errors[:amount], "must be greater than 0"
  end

  test "is invalid when amount is negative" do
    expense = Expense.new(date: Date.today, description: "Refund", amount: -50)
    assert_not expense.valid?
    assert_includes expense.errors[:amount], "must be greater than 0"
  end

  test "is valid without category" do
    expense = Expense.new(date: Date.today, description: "Coffee", amount: 15)
    assert expense.valid?
  end

  # ---------------------------------------------------------------------------
  # Associations
  # ---------------------------------------------------------------------------

  test "has many expense_allocations" do
    expense = expenses(:food_expense)
    assert_equal 1, expense.expense_allocations.count
  end

  test "has many card_top_ups through expense_allocations" do
    expense = expenses(:food_expense)
    assert_includes expense.card_top_ups, card_top_ups(:salary_top_up)
  end

  test "destroys expense_allocations when destroyed" do
    expense = expenses(:food_expense)
    allocation_id = expense.expense_allocations.first.id
    expense.destroy
    assert_nil ExpenseAllocation.find_by(id: allocation_id)
  end

  # ---------------------------------------------------------------------------
  # allocated_amount
  # ---------------------------------------------------------------------------

  test "allocated_amount sums all allocation amounts" do
    expense = expenses(:food_expense)
    assert_equal 300.0, expense.allocated_amount.to_f
  end

  test "allocated_amount returns 0 when there are no allocations" do
    expense = Expense.new(date: Date.today, description: "Ghost", amount: 50)
    assert_equal 0, expense.allocated_amount
  end

  # ---------------------------------------------------------------------------
  # unallocated_amount
  # ---------------------------------------------------------------------------

  test "unallocated_amount returns zero when fully allocated" do
    expense = expenses(:food_expense)
    # amount=300, allocated=300
    assert_equal 0, expense.unallocated_amount
  end

  test "unallocated_amount returns amount when nothing is allocated" do
    expense = Expense.new(date: Date.today, description: "Ghost", amount: 75)
    assert_equal 75, expense.unallocated_amount
  end

  # ---------------------------------------------------------------------------
  # after_create :allocate_to_top_ups — isolated tests (fixture data removed)
  # ---------------------------------------------------------------------------

  # Each test in this section resets the DB to a clean state so fixture
  # top-ups do not interfere with allocation logic.

  def isolate_allocations
    ExpenseAllocation.delete_all
    Expense.delete_all
    SourceDeduction.delete_all
    CardTopUp.delete_all
  end

  test "creates expense_allocations after save when a top-up has balance" do
    isolate_allocations
    CardTopUp.create!(date: Date.today, net_amount: 1000, source_type: "transfer")
    expense = Expense.create!(date: Date.today, description: "Test", amount: 200)
    assert_equal 1, expense.expense_allocations.count
    assert_equal 200.0, expense.expense_allocations.first.amount.to_f
  end

  test "allocates to top-up with highest cost_ratio first" do
    isolate_allocations

    # low_ratio: net 1000, no deductions → cost_ratio = 0
    low_ratio = CardTopUp.create!(date: Date.today, net_amount: 1000, source_type: "transfer")

    # high_ratio: net 700, deduction 300 → gross 1000, ratio = 30%
    high_ratio = CardTopUp.create!(date: Date.today, net_amount: 700, source_type: "salary")
    SourceDeduction.create!(card_top_up: high_ratio, name: "CAS", amount: 300)

    # expense 500 <= high_ratio balance 700, so it should all go to high_ratio
    expense = Expense.create!(date: Date.today, description: "Prioritised", amount: 500)

    alloc_high = expense.expense_allocations.find_by(card_top_up: high_ratio)
    alloc_low  = expense.expense_allocations.find_by(card_top_up: low_ratio)

    assert_not_nil alloc_high
    assert_equal 500.0, alloc_high.amount.to_f
    assert_nil alloc_low
  end

  test "allocates across multiple top-ups when a single top-up is not enough" do
    isolate_allocations

    CardTopUp.create!(date: Date.today, net_amount: 300, source_type: "transfer")
    CardTopUp.create!(date: Date.today, net_amount: 400, source_type: "transfer")

    expense = Expense.create!(date: Date.today, description: "Big purchase", amount: 500)

    assert_equal 500.0, expense.expense_allocations.sum(:amount).to_f
  end

  test "allocates only up to each top-up available balance" do
    isolate_allocations

    t = CardTopUp.create!(date: Date.today, net_amount: 200, source_type: "transfer")
    expense = Expense.create!(date: Date.today, description: "Exceeds balance", amount: 500)

    alloc = expense.expense_allocations.find_by(card_top_up: t)
    assert_not_nil alloc
    assert_equal 200.0, alloc.amount.to_f
  end

  test "does not create allocations when no top-ups have remaining balance" do
    isolate_allocations

    expense = Expense.create!(date: Date.today, description: "No funds", amount: 100)
    assert_equal 0, expense.expense_allocations.count
  end

  test "allocates exact amount when expense matches top-up balance exactly" do
    isolate_allocations

    top_up = CardTopUp.create!(date: Date.today, net_amount: 250, source_type: "transfer")
    expense = Expense.create!(date: Date.today, description: "Exact match", amount: 250)

    alloc = expense.expense_allocations.find_by(card_top_up: top_up)
    assert_not_nil alloc
    assert_equal 250.0, alloc.amount.to_f
  end

  test "respects remaining balance after prior allocations" do
    isolate_allocations

    top_up = CardTopUp.create!(date: Date.today, net_amount: 500, source_type: "transfer")

    # First expense uses 300
    Expense.create!(date: Date.today, description: "First", amount: 300)
    assert_equal 200.0, top_up.reload.remaining_balance.to_f

    # Second expense should only get the remaining 200
    expense2 = Expense.create!(date: Date.today, description: "Second", amount: 400)
    alloc = expense2.expense_allocations.find_by(card_top_up: top_up)
    assert_equal 200.0, alloc.amount.to_f
  end
end
