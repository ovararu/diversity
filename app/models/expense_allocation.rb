class ExpenseAllocation < ApplicationRecord
  belongs_to :expense
  belongs_to :card_top_up

  validates :amount, presence: true, numericality: { greater_than: 0 }

  # Real cost: what the employer actually paid for this allocated amount
  # e.g. 200 RON from a top-up with net=500, gross=1000 → real cost = 400
  def real_cost
    top_up = card_top_up
    return amount if top_up.net_amount.zero?
    (amount * top_up.gross_amount_computed / top_up.net_amount).round(2)
  end
end
