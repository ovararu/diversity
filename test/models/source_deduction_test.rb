require "test_helper"

class SourceDeductionTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Validations
  # ---------------------------------------------------------------------------

  test "is valid with all required attributes" do
    deduction = SourceDeduction.new(
      card_top_up: card_top_ups(:transfer_top_up),
      name: "CAS",
      amount: 500
    )
    assert deduction.valid?
  end

  test "is invalid without name" do
    deduction = SourceDeduction.new(
      card_top_up: card_top_ups(:transfer_top_up),
      amount: 500
    )
    assert_not deduction.valid?
    assert_includes deduction.errors[:name], "can't be blank"
  end

  test "is invalid without amount" do
    deduction = SourceDeduction.new(
      card_top_up: card_top_ups(:transfer_top_up),
      name: "CAS"
    )
    assert_not deduction.valid?
    assert_includes deduction.errors[:amount], "can't be blank"
  end

  test "is invalid when amount is negative" do
    deduction = SourceDeduction.new(
      card_top_up: card_top_ups(:transfer_top_up),
      name: "CAS",
      amount: -10
    )
    assert_not deduction.valid?
    assert_includes deduction.errors[:amount], "must be greater than or equal to 0"
  end

  test "is valid when amount is zero" do
    deduction = SourceDeduction.new(
      card_top_up: card_top_ups(:transfer_top_up),
      name: "CAS",
      amount: 0
    )
    assert deduction.valid?
  end

  test "is invalid without card_top_up" do
    deduction = SourceDeduction.new(name: "CAS", amount: 500)
    assert_not deduction.valid?
  end

  # ---------------------------------------------------------------------------
  # Associations
  # ---------------------------------------------------------------------------

  test "belongs to card_top_up" do
    deduction = source_deductions(:cas_deduction)
    assert_equal card_top_ups(:salary_top_up), deduction.card_top_up
  end

  # ---------------------------------------------------------------------------
  # Constants
  # ---------------------------------------------------------------------------

  test "PAID_BY includes employee and employer" do
    assert_includes SourceDeduction::PAID_BY, "employee"
    assert_includes SourceDeduction::PAID_BY, "employer"
  end

  # ---------------------------------------------------------------------------
  # Optional fields
  # ---------------------------------------------------------------------------

  test "is valid without percentage" do
    deduction = SourceDeduction.new(
      card_top_up: card_top_ups(:transfer_top_up),
      name: "Custom fee",
      amount: 100
    )
    assert deduction.valid?
  end

  test "is valid without paid_by" do
    deduction = SourceDeduction.new(
      card_top_up: card_top_ups(:transfer_top_up),
      name: "Custom fee",
      amount: 100
    )
    assert deduction.valid?
  end
end
