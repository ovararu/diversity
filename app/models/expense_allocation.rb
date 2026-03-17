class ExpenseAllocation < ApplicationRecord
  belongs_to :expense
  belongs_to :card_top_up

  validates :amount, presence: true, numericality: { greater_than: 0 }
end
