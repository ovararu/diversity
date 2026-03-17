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
