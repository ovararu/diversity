require "test_helper"

class ExpensesControllerTest < ActionDispatch::IntegrationTest
  # ---------------------------------------------------------------------------
  # GET /expenses (index)
  # ---------------------------------------------------------------------------

  test "GET index returns 200" do
    get expenses_path
    assert_response :success
  end

  test "GET index renders expense descriptions" do
    get expenses_path
    assert_match expenses(:food_expense).description, response.body
    assert_match expenses(:transport_expense).description, response.body
  end

  test "GET index lists expenses ordered by date descending" do
    get expenses_path
    newer_pos = response.body.index(expenses(:transport_expense).date.strftime("%d.%m.%Y"))
    older_pos = response.body.index(expenses(:food_expense).date.strftime("%d.%m.%Y"))
    assert newer_pos < older_pos
  end

  # ---------------------------------------------------------------------------
  # GET /expenses/:id (show)
  # ---------------------------------------------------------------------------

  test "GET show returns 200" do
    get expense_path(expenses(:food_expense))
    assert_response :success
  end

  test "GET show renders the expense description" do
    expense = expenses(:food_expense)
    get expense_path(expense)
    assert_match expense.description, response.body
  end

  test "GET show returns 404 for unknown id" do
    get expense_path(id: 999999)
    assert_response :not_found
  end

  # ---------------------------------------------------------------------------
  # GET /expenses/new (new)
  # ---------------------------------------------------------------------------

  test "GET new returns 200" do
    get new_expense_path
    assert_response :success
  end

  test "GET new form has today's date pre-filled" do
    get new_expense_path
    assert_match Date.today.strftime("%Y-%m-%d"), response.body
  end

  # ---------------------------------------------------------------------------
  # GET /expenses/:id/edit (edit)
  # ---------------------------------------------------------------------------

  test "GET edit returns 200" do
    get edit_expense_path(expenses(:food_expense))
    assert_response :success
  end

  test "GET edit returns 404 for unknown id" do
    get edit_expense_path(id: 999999)
    assert_response :not_found
  end

  # ---------------------------------------------------------------------------
  # POST /expenses (create)
  # ---------------------------------------------------------------------------

  test "POST create with valid params creates a new Expense" do
    assert_difference "Expense.count", 1 do
      post expenses_path, params: {
        expense: {
          date: "2026-03-10",
          description: "Dinner",
          amount: "120.50",
          category: "Food"
        }
      }
    end
  end

  test "POST create with valid params redirects to the new expense" do
    post expenses_path, params: {
      expense: {
        date: "2026-03-10",
        description: "Dinner",
        amount: "120.50"
      }
    }
    assert_redirected_to expense_path(Expense.last)
  end

  test "POST create sets flash notice on success" do
    post expenses_path, params: {
      expense: {
        date: "2026-03-10",
        description: "Dinner",
        amount: "120.50"
      }
    }
    assert_equal "Expense recorded and allocated.", flash[:notice]
  end

  test "POST create persists the correct amount" do
    post expenses_path, params: {
      expense: { date: "2026-03-10", description: "Dinner", amount: "99.99" }
    }
    assert_equal 99.99, Expense.last.amount.to_f
  end

  test "POST create persists the category" do
    post expenses_path, params: {
      expense: { date: "2026-03-10", description: "Bus", amount: "10", category: "Transport" }
    }
    assert_equal "Transport", Expense.last.category
  end

  test "POST create triggers allocation when top-ups have balance" do
    post expenses_path, params: {
      expense: { date: "2026-03-10", description: "Dinner", amount: "50.00" }
    }
    # Fixtures provide top-ups with remaining balance; at least one allocation must be created.
    assert Expense.last.expense_allocations.any?
  end

  test "POST create with invalid params does not create an Expense" do
    assert_no_difference "Expense.count" do
      post expenses_path, params: {
        expense: { date: "", description: "", amount: "" }
      }
    end
  end

  test "POST create with invalid params renders new with 422" do
    post expenses_path, params: {
      expense: { date: "", description: "", amount: "" }
    }
    assert_response :unprocessable_entity
  end

  test "POST create with zero amount renders new with 422" do
    post expenses_path, params: {
      expense: { date: "2026-03-10", description: "Zero", amount: "0" }
    }
    assert_response :unprocessable_entity
  end

  test "POST create with negative amount renders new with 422" do
    post expenses_path, params: {
      expense: { date: "2026-03-10", description: "Negative", amount: "-10" }
    }
    assert_response :unprocessable_entity
  end

  # ---------------------------------------------------------------------------
  # PATCH /expenses/:id (update)
  # ---------------------------------------------------------------------------

  test "PATCH update with valid params updates the description" do
    expense = expenses(:food_expense)
    patch expense_path(expense), params: {
      expense: { description: "Updated description" }
    }
    assert_equal "Updated description", expense.reload.description
  end

  test "PATCH update with valid params updates the amount" do
    expense = expenses(:food_expense)
    patch expense_path(expense), params: {
      expense: { amount: "350.00" }
    }
    assert_equal 350.0, expense.reload.amount.to_f
  end

  test "PATCH update with valid params redirects to the expense" do
    expense = expenses(:food_expense)
    patch expense_path(expense), params: {
      expense: { description: "Updated" }
    }
    assert_redirected_to expense_path(expense)
  end

  test "PATCH update sets flash notice on success" do
    expense = expenses(:food_expense)
    patch expense_path(expense), params: {
      expense: { description: "Updated" }
    }
    assert_equal "Expense updated.", flash[:notice]
  end

  test "PATCH update destroys old allocations and creates new ones" do
    expense = expenses(:food_expense)
    old_ids = expense.expense_allocations.pluck(:id)

    patch expense_path(expense), params: {
      expense: { amount: expense.amount.to_s }
    }

    old_ids.each do |id|
      assert_nil ExpenseAllocation.find_by(id: id), "Old allocation #{id} should have been deleted"
    end
    assert expense.reload.expense_allocations.any?
  end

  test "PATCH update with invalid params renders edit with 422" do
    expense = expenses(:food_expense)
    patch expense_path(expense), params: {
      expense: { amount: "-1" }
    }
    assert_response :unprocessable_entity
  end

  test "PATCH update with invalid params does not change the record" do
    expense = expenses(:food_expense)
    original_amount = expense.amount
    patch expense_path(expense), params: {
      expense: { amount: "-1" }
    }
    assert_equal original_amount, expense.reload.amount
  end

  # ---------------------------------------------------------------------------
  # DELETE /expenses/:id (destroy)
  # ---------------------------------------------------------------------------

  test "DELETE destroy removes the expense" do
    expense = Expense.create!(date: Date.today, description: "Temp", amount: 10)
    assert_difference "Expense.count", -1 do
      delete expense_path(expense)
    end
  end

  test "DELETE destroy removes all associated allocations" do
    # Create an isolated expense with a known allocation (no auto-alloc from fixtures)
    ExpenseAllocation.delete_all
    Expense.delete_all
    SourceDeduction.delete_all
    CardTopUp.delete_all

    top_up  = CardTopUp.create!(date: Date.today, net_amount: 500, source_type: "transfer")
    expense = Expense.create!(date: Date.today, description: "Temp", amount: 10)

    assert_difference "ExpenseAllocation.count", -expense.expense_allocations.count do
      delete expense_path(expense)
    end
  end

  test "DELETE destroy redirects to index" do
    expense = Expense.create!(date: Date.today, description: "Temp", amount: 10)
    delete expense_path(expense)
    assert_redirected_to expenses_path
  end

  test "DELETE destroy sets flash notice" do
    expense = Expense.create!(date: Date.today, description: "Temp", amount: 10)
    delete expense_path(expense)
    assert_equal "Expense deleted.", flash[:notice]
  end
end
