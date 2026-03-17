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
  # Calculation with total_cost = 10_000 RON (Salariu Complet, no personal deduction)
  # ---------------------------------------------------------------------------
  # gross = round(10000 / 1.0225)  = round(9779.951...) = 9780  (Salariu Brut)
  # cam   = round(9780 * 0.0225)   = round(220.05)      = 220
  # cas   = round(9780 * 0.25)     = 2445
  # cass  = round(9780 * 0.10)     = 978
  # iv    = round((9780-2445-978) * 0.10) = round(635.7) = 636
  # net   = 9780 - 2445 - 978 - 636 = 5721

  def result
    @result ||= SalaryCalculator.calculate(10_000)
  end

  test "returns total_cost unchanged" do
    assert_equal 10_000, result[:total_cost]
  end

  test "derives gross (Salariu Brut) from total_cost" do
    assert_equal 9780, result[:gross]
  end

  test "calculates CAM correctly" do
    assert_equal 220, result[:cam]
  end

  test "calculates CAS correctly" do
    assert_equal 2445, result[:cas]
  end

  test "calculates CASS correctly" do
    assert_equal 978, result[:cass]
  end

  test "calculates IV correctly (applied on gross minus CAS minus CASS)" do
    assert_equal 636, result[:iv]
  end

  test "calculates net correctly" do
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
    # 4279 / 10000 * 100 = 42.79
    assert_equal 42.79, result[:cost_ratio]
  end

  # ---------------------------------------------------------------------------
  # Personal deduction reduces IV base
  # ---------------------------------------------------------------------------
  # gross = 9780, personal_deduction = 300
  # iv = round((9780 - 2445 - 978 - 300) * 0.10) = round(6057 * 0.10) = round(605.7) = 606
  # net = 9780 - 2445 - 978 - 606 = 5751

  test "personal deduction reduces IV" do
    r = SalaryCalculator.calculate(10_000, personal_deduction: 300)
    assert_equal 606, r[:iv]
  end

  test "personal deduction increases net salary" do
    r = SalaryCalculator.calculate(10_000, personal_deduction: 300)
    assert_equal 5751, r[:net]
  end

  test "personal deduction does not affect CAM" do
    r = SalaryCalculator.calculate(10_000, personal_deduction: 300)
    assert_equal 220, r[:cam]
  end

  test "personal deduction does not affect CAS" do
    r = SalaryCalculator.calculate(10_000, personal_deduction: 300)
    assert_equal 2445, r[:cas]
  end

  test "personal deduction does not affect CASS" do
    r = SalaryCalculator.calculate(10_000, personal_deduction: 300)
    assert_equal 978, r[:cass]
  end

  # ---------------------------------------------------------------------------
  # Edge cases
  # ---------------------------------------------------------------------------

  test "handles string input by converting to decimal" do
    r = SalaryCalculator.calculate("10000")
    assert_equal 9780, r[:gross]
    assert_equal 2445, r[:cas]
  end

  test "handles zero total_cost" do
    r = SalaryCalculator.calculate(0)
    assert_equal 0, r[:total_cost]
    assert_equal 0, r[:gross]
    assert_equal 0, r[:cam]
    assert_equal 0, r[:net]
  end

  test "returns a hash with all expected keys" do
    r = SalaryCalculator.calculate(5000)
    %i[total_cost gross cas cass iv cam net total_employee_taxes total_employer_taxes total_taxes cost_ratio].each do |key|
      assert r.key?(key), "Expected result to have key :#{key}"
    end
  end

  test "net plus all employee taxes equals gross (Salariu Brut)" do
    r = SalaryCalculator.calculate(10_000)
    assert_equal r[:gross], r[:net] + r[:cas] + r[:cass] + r[:iv]
  end

  test "gross plus CAM equals total_cost (within rounding tolerance)" do
    r = SalaryCalculator.calculate(10_000)
    # gross + cam should equal total_cost, with at most 1 RON rounding difference
    assert_in_delta r[:total_cost], r[:gross] + r[:cam], 1
  end

  test "cost_ratio is between 0 and 100" do
    r = SalaryCalculator.calculate(10_000)
    assert r[:cost_ratio] >= 0
    assert r[:cost_ratio] <= 100
  end

  test "total_cost 5000 produces proportionally halved gross and cam compared to 10000" do
    r1 = SalaryCalculator.calculate(5_000)
    r2 = SalaryCalculator.calculate(10_000)
    # gross and cam should each be roughly half (allow for 1 RON rounding difference)
    assert_in_delta r2[:gross], r1[:gross] * 2, 1
    assert_in_delta r2[:cam],   r1[:cam]   * 2, 1
  end
end
