module SalaryCalculator
  CAS_RATE  = 0.25
  CASS_RATE = 0.10
  IV_RATE   = 0.10
  CAM_RATE  = 0.0225

  # gross      = Salariu Brut (user input)
  # cam        = gross * 2.25%  — paid by employer on top of gross
  # total_cost = gross + cam    — Salariu Complet, total employer expenditure
  # CAS/CASS/IV are employee deductions calculated on gross only
  def self.calculate(gross, personal_deduction: 0)
    gross = gross.to_d.round(0)
    cam   = (gross * CAM_RATE).round(0)
    total_cost = gross + cam
    cas   = (gross * CAS_RATE).round(0)
    cass  = (gross * CASS_RATE).round(0)
    iv    = ((gross - cas - cass - personal_deduction.to_d) * IV_RATE).round(0)
    net   = gross - cas - cass - iv

    {
      total_cost: total_cost,
      gross: gross,
      cam: cam,
      cas: cas,
      cass: cass,
      iv: iv,
      net: net,
      total_employee_taxes: cas + cass + iv,
      total_employer_taxes: cam,
      total_taxes: cas + cass + iv + cam,
      cost_ratio: ((cas + cass + iv + cam) / total_cost.to_d * 100).round(2)
    }
  end
end
