module SalaryCalculator
  CAS_RATE  = 0.25
  CASS_RATE = 0.10
  IV_RATE   = 0.10
  CAM_RATE  = 0.0225

  # total_cost = what the employer spends in total (Salariu Complet)
  # gross      = Salariu Brut = total_cost / (1 + CAM_RATE), rounded to integer
  def self.calculate(total_cost, personal_deduction: 0)
    total_cost = total_cost.to_d
    gross = (total_cost / (1 + CAM_RATE)).round(0)
    cam   = (gross * CAM_RATE).round(0)
    cas   = (gross * CAS_RATE).round(0)
    cass  = (gross * CASS_RATE).round(0)
    iv    = ((gross - cas - cass - personal_deduction.to_d) * IV_RATE).round(0)
    net   = gross - cas - cass - iv

    {
      total_cost: total_cost.round(0),
      gross: gross,
      cam: cam,
      cas: cas,
      cass: cass,
      iv: iv,
      net: net,
      total_employee_taxes: cas + cass + iv,
      total_employer_taxes: cam,
      total_taxes: cas + cass + iv + cam,
      cost_ratio: ((cas + cass + iv + cam) / total_cost * 100).round(2)
    }
  end
end
