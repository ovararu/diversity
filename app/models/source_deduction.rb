class SourceDeduction < ApplicationRecord
  belongs_to :card_top_up

  validates :name, :amount, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }

  PAID_BY = %w[employee employer].freeze
end
