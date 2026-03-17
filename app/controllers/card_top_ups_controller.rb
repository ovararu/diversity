class CardTopUpsController < ApplicationController
  before_action :set_card_top_up, only: %i[show edit update destroy]

  def index
    @card_top_ups = CardTopUp.includes(:source_deductions, :expense_allocations).order(date: :desc)
    @total_loaded   = @card_top_ups.sum(&:net_amount)
    @total_spent    = @card_top_ups.sum(&:allocated_amount)
    @card_balance   = @total_loaded - @total_spent
  end

  def show
  end

  def new
    @card_top_up = CardTopUp.new(date: Date.today, source_type: "salary")
    @card_top_up.source_deductions.build
  end

  def edit
  end

  def create
    @card_top_up = CardTopUp.new(card_top_up_params)

    if @card_top_up.save
      redirect_to @card_top_up, notice: "Top-up created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @card_top_up.update(card_top_up_params)
      redirect_to @card_top_up, notice: "Top-up updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @card_top_up.destroy
    redirect_to card_top_ups_path, notice: "Top-up deleted."
  end

  def salary_preview
    gross = params[:gross].to_d
    render json: SalaryCalculator.calculate(gross,
      personal_deduction: params[:personal_deduction].to_d)
  end

  private

  def set_card_top_up
    @card_top_up = CardTopUp.find(params[:id])
  end

  def card_top_up_params
    params.require(:card_top_up).permit(
      :date, :description, :source_type, :net_amount, :gross_amount, :eur_rate,
      source_deductions_attributes: %i[id name amount percentage paid_by _destroy]
    )
  end
end
