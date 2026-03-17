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
  # Reference case: gross (Salariu Brut) = 9780
  # ---------------------------------------------------------------------------
  # cam        = round(9780 * 0.0225)          = round(220.05)  = 220
  # total_cost = 9780 + 220                    = 10000          (Salariu Complet)
  # cas        = round(9780 * 0.25)            = 2445
  # cass       = round(9780 * 0.10)            = 978
  # iv         = round((9780-2445-978) * 0.10) = round(635.7)   = 636
  # net        = 9780 - 2445 - 978 - 636       = 5721

  def result
    @result ||= SalaryCalculator.calculate(9780)
  end

  test "input gross (Salariu Brut) is returned unchanged" do
    assert_equal 9780, result[:gross]
  end

  test "CAM is 2.25% of gross" do
    assert_equal 220, result[:cam]
  end

  test "total_cost (Salariu Complet) is gross plus CAM" do
    assert_equal 10000, result[:total_cost]
  end

  test "CAS is 25% of gross" do
    assert_equal 2445, result[:cas]
  end

  test "CASS is 10% of gross" do
    assert_equal 978, result[:cass]
  end

  test "IV is 10% of gross minus CAS minus CASS" do
    assert_equal 636, result[:iv]
  end

  test "net salary is correct" do
    assert_equal 5721, result[:net]
  end

  test "total_employee_taxes is CAS + CASS + IV" do
    assert_equal 4059, result[:total_employee_taxes]
  end

  test "total_employer_taxes is CAM" do
    assert_equal 220, result[:total_employer_taxes]
  end

  test "total_taxes is employee plus employer taxes" do
    assert_equal 4279, result[:total_taxes]
  end

  test "cost_ratio is total_taxes over total_cost" do
    # 4279 / 10000 * 100 = 42.79%
    assert_equal 42.79, result[:cost_ratio]
  end

  test "net plus employee taxes equals gross (Salariu Brut)" do
    assert_equal result[:gross], result[:net] + result[:cas] + result[:cass] + result[:iv]
  end

  test "gross plus CAM equals total_cost" do
    assert_equal result[:total_cost], result[:gross] + result[:cam]
  end

  # ---------------------------------------------------------------------------
  # Personal deduction reduces IV base (gross = 9780, deduction = 300)
  # ---------------------------------------------------------------------------
  # iv = round((9780 - 2445 - 978 - 300) * 0.10) = round(605.7) = 606
  # net = 9780 - 2445 - 978 - 606 = 5751

  test "personal deduction reduces IV" do
    r = SalaryCalculator.calculate(9780, personal_deduction: 300)
    assert_equal 606, r[:iv]
  end

  test "personal deduction increases net salary" do
    r = SalaryCalculator.calculate(9780, personal_deduction: 300)
    assert_equal 5751, r[:net]
  end

  test "personal deduction does not affect CAM" do
    r = SalaryCalculator.calculate(9780, personal_deduction: 300)
    assert_equal 220, r[:cam]
  end

  test "personal deduction does not affect CAS" do
    r = SalaryCalculator.calculate(9780, personal_deduction: 300)
    assert_equal 2445, r[:cas]
  end

  test "personal deduction does not affect CASS" do
    r = SalaryCalculator.calculate(9780, personal_deduction: 300)
    assert_equal 978, r[:cass]
  end

  test "personal deduction does not affect total_cost" do
    r = SalaryCalculator.calculate(9780, personal_deduction: 300)
    assert_equal 10000, r[:total_cost]
  end

  # ---------------------------------------------------------------------------
  # Edge cases
  # ---------------------------------------------------------------------------

  test "handles string input" do
    r = SalaryCalculator.calculate("9780")
    assert_equal 9780, r[:gross]
    assert_equal 10000, r[:total_cost]
  end

  test "handles zero gross" do
    r = SalaryCalculator.calculate(0)
    assert_equal 0, r[:gross]
    assert_equal 0, r[:cam]
    assert_equal 0, r[:total_cost]
    assert_equal 0, r[:net]
  end

  test "returns a hash with all expected keys" do
    r = SalaryCalculator.calculate(9780)
    %i[total_cost gross cas cass iv cam net total_employee_taxes total_employer_taxes total_taxes cost_ratio].each do |key|
      assert r.key?(key), "Expected result to have key :#{key}"
    end
  end

  test "cost_ratio is between 0 and 100" do
    r = SalaryCalculator.calculate(9780)
    assert r[:cost_ratio] >= 0
    assert r[:cost_ratio] <= 100
  end

  test "doubling gross doubles all monetary values within rounding tolerance" do
    r1 = SalaryCalculator.calculate(5000)
    r2 = SalaryCalculator.calculate(10000)
    %i[cam cas cass net total_cost].each do |key|
      assert_in_delta r2[key], r1[key] * 2, 2, "#{key} should scale linearly"
    end
  end
end
