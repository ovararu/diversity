module SalaryCalculator
  CAS_RATE       = 0.25
  CASS_RATE      = 0.10
  IV_RATE        = 0.10
  CAM_RATE       = 0.0225

  def self.calculate(gross, personal_deduction: 0)
    gross = gross.to_d
    cam  = (gross * CAM_RATE).round(2)
    cas  = (gross * CAS_RATE).round(2)
    cass = (gross * CASS_RATE).round(2)
    iv   = ((gross - cam - cas - cass - personal_deduction.to_d) * IV_RATE).round(2)
    net  = gross - cas - cass - iv

    {
      gross: gross,
      cas: cas,
      cass: cass,
      iv: iv,
      cam: cam,
      net: net,
      total_employee_taxes: cas + cass + iv,
      total_employer_taxes: cam,
      total_taxes: cas + cass + iv + cam,
      cost_ratio: ((cas + cass + iv + cam) / (net + cas + cass + iv + cam) * 100).round(2)
    }
  end
end
