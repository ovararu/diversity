require "test_helper"

class SalaryCalculatorTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Constants
  # ---------------------------------------------------------------------------

  test "CAS_RATE is 25%" do
    assert_equal 0.25, SalaryCalculator::CAS_RATE
  end

  test "CASS_RATE is 10%" do
    assert_equal 0.10, SalaryCalculator::CASS_RATE
  end

  test "IV_RATE is 10%" do
    assert_equal 0.10, SalaryCalculator::IV_RATE
  end

  test "CAM_RATE is 2.25%" do
    assert_equal 0.0225, SalaryCalculator::CAM_RATE
  end

  # ---------------------------------------------------------------------------
  # Calculation with gross = 10_000 RON (no personal deduction)
  # ---------------------------------------------------------------------------
  # CAS  = 10000 * 0.25 = 2500
  # CASS = 10000 * 0.10 = 1000
  # IV   = (10000 - 2500 - 1000 - 0) * 0.10 = 650
  # CAM  = 10000 * 0.0225 = 225
  # net  = 10000 - 2500 - 1000 - 650 = 5850

  def result
    @result ||= SalaryCalculator.calculate(10_000)
  end

  test "returns gross unchanged" do
    assert_equal 10_000, result[:gross]
  end

  test "calculates CAS correctly" do
    assert_equal 2500.0, result[:cas].to_f
  end

  test "calculates CASS correctly" do
    assert_equal 1000.0, result[:cass].to_f
  end

  test "calculates IV correctly (applied on gross minus CAS minus CASS)" do
    assert_equal 650.0, result[:iv].to_f
  end

  test "calculates CAM correctly" do
    assert_equal 225.0, result[:cam].to_f
  end

  test "calculates net correctly" do
    assert_equal 5850.0, result[:net].to_f
  end

  test "total_employee_taxes is CAS + CASS + IV" do
    assert_equal 4150.0, result[:total_employee_taxes].to_f
  end

  test "total_employer_taxes is CAM" do
    assert_equal 225.0, result[:total_employer_taxes].to_f
  end

  test "total_taxes is employee plus employer taxes" do
    assert_equal 4375.0, result[:total_taxes].to_f
  end

  test "cost_ratio is total_taxes over total cost (net + all taxes)" do
    # (4150 + 225) / (5850 + 4150 + 225) * 100 = 4375 / 10225 * 100
    expected = (4375.0 / 10225.0 * 100).round(2)
    assert_equal expected, result[:cost_ratio]
  end

  # ---------------------------------------------------------------------------
  # Personal deduction reduces IV base
  # ---------------------------------------------------------------------------
  # gross=10000, personal_deduction=300
  # CAS  = 2500, CASS = 1000
  # IV   = (10000 - 2500 - 1000 - 300) * 0.10 = 6200 * 0.10 = 620
  # net  = 10000 - 2500 - 1000 - 620 = 5880

  test "personal deduction reduces IV" do
    r = SalaryCalculator.calculate(10_000, personal_deduction: 300)
    assert_equal 620.0, r[:iv].to_f
  end

  test "personal deduction increases net salary" do
    r = SalaryCalculator.calculate(10_000, personal_deduction: 300)
    assert_equal 5880.0, r[:net].to_f
  end

  test "personal deduction does not affect CAS" do
    r = SalaryCalculator.calculate(10_000, personal_deduction: 300)
    assert_equal 2500.0, r[:cas].to_f
  end

  test "personal deduction does not affect CASS" do
    r = SalaryCalculator.calculate(10_000, personal_deduction: 300)
    assert_equal 1000.0, r[:cass].to_f
  end

  test "personal deduction does not affect CAM" do
    r = SalaryCalculator.calculate(10_000, personal_deduction: 300)
    assert_equal 225.0, r[:cam].to_f
  end

  # ---------------------------------------------------------------------------
  # Edge cases
  # ---------------------------------------------------------------------------

  test "handles string input by converting to decimal" do
    r = SalaryCalculator.calculate("5000")
    assert_equal 5000, r[:gross]
    assert_equal 1250.0, r[:cas].to_f
  end

  test "handles zero gross" do
    r = SalaryCalculator.calculate(0)
    assert_equal 0, r[:gross]
    assert_equal 0, r[:cas].to_f
    assert_equal 0, r[:net].to_f
  end

  test "returns a hash with all expected keys" do
    r = SalaryCalculator.calculate(3000)
    %i[gross cas cass iv cam net total_employee_taxes total_employer_taxes total_taxes cost_ratio].each do |key|
      assert r.key?(key), "Expected result to have key :#{key}"
    end
  end

  test "net plus all employee taxes equals gross" do
    r = SalaryCalculator.calculate(7500)
    assert_equal r[:gross].to_f, (r[:net] + r[:cas] + r[:cass] + r[:iv]).to_f
  end

  test "cost_ratio is between 0 and 100" do
    r = SalaryCalculator.calculate(10_000)
    assert r[:cost_ratio] >= 0
    assert r[:cost_ratio] <= 100
  end

  test "different gross amounts produce proportionally scaled taxes" do
    r1 = SalaryCalculator.calculate(5000)
    r2 = SalaryCalculator.calculate(10_000)
    assert_equal r1[:cas].to_f * 2, r2[:cas].to_f
    assert_equal r1[:cass].to_f * 2, r2[:cass].to_f
    assert_equal r1[:cam].to_f * 2, r2[:cam].to_f
  end
end
