class CardTopUp < ApplicationRecord
  has_many :source_deductions, dependent: :destroy
  has_many :expense_allocations, dependent: :destroy
  has_many :expenses, through: :expense_allocations

  accepts_nested_attributes_for :source_deductions, allow_destroy: true, reject_if: :all_blank

  validates :date, :net_amount, :source_type, presence: true
  validates :net_amount, numericality: { greater_than: 0 }

  SOURCE_TYPES = %w[salary transfer other].freeze

  def total_deductions
    source_deductions.sum(:amount)
  end

  # Salariu Brut: net + employee deductions (CAS + CASS + IV)
  def salariu_brut
    employee_total = source_deductions.where(paid_by: "employee").sum(:amount)
    net_amount + employee_total
  end

  # Salariu Complet: net + ALL deductions (employee + employer/CAM)
  def gross_amount_computed
    net_amount + total_deductions
  end

  def cost_ratio
    total = gross_amount_computed
    return 0 if total.zero?
    (total_deductions / total * 100).round(2)
  end

  def allocated_amount
    expense_allocations.sum(:amount)
  end

  def remaining_balance
    net_amount - allocated_amount
  end

  def eur_net
    return nil unless eur_rate && eur_rate > 0
    (net_amount / eur_rate).round(2)
  end

  def self.ordered_by_cost_ratio
    all.sort_by(&:cost_ratio).reverse
  end

  def self.with_remaining_balance
    all.select { |t| t.remaining_balance > 0 }
  end
end
