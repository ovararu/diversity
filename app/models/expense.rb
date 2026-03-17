class Expense < ApplicationRecord
  has_many :expense_allocations, dependent: :destroy
  has_many :card_top_ups, through: :expense_allocations

  validates :date, :description, :amount, presence: true
  validates :amount, numericality: { greater_than: 0 }

  after_create :allocate_to_top_ups

  def allocated_amount
    expense_allocations.sum(:amount)
  end

  def unallocated_amount
    amount - allocated_amount
  end

  # Total real cost: sum of real_cost across all allocations
  def real_cost
    expense_allocations.includes(:card_top_up).sum { |a| a.real_cost }
  end

  # Weighted cost ratio: percentage of taxes in the real cost
  def cost_ratio
    return 0 if amount.zero? || real_cost.zero?
    ((real_cost - amount) / amount.to_d * 100).round(2)
  end

  private

  def allocate_to_top_ups
    remaining = amount
    top_ups = CardTopUp.with_remaining_balance.sort_by(&:cost_ratio).reverse

    top_ups.each do |top_up|
      break if remaining <= 0

      available = top_up.remaining_balance
      allocated = [ remaining, available ].min

      expense_allocations.create!(card_top_up: top_up, amount: allocated)
      remaining -= allocated
    end
  end
end
