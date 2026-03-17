class ExpensesController < ApplicationController
  before_action :set_expense, only: %i[show edit update destroy]

  def index
    @expenses = Expense.includes(:expense_allocations, :card_top_ups).order(date: :desc)
  end

  def show
  end

  def new
    @expense = Expense.new(date: Date.today)
  end

  def edit
  end

  def create
    @expense = Expense.new(expense_params)

    if @expense.save
      redirect_to @expense, notice: "Expense recorded and allocated."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @expense.expense_allocations.destroy_all
    if @expense.update(expense_params)
      @expense.send(:allocate_to_top_ups)
      redirect_to @expense, notice: "Expense updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    redirect_to expenses_path, notice: "Expense deleted."
  end

  private

  def set_expense
    @expense = Expense.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:date, :description, :amount, :category)
  end
end
