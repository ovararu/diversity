import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "sourceType", "salarySection", "gross", "netAmount", "grossAmount",
    "preview", "previewGross", "previewCas", "previewCass", "previewIv", "previewCam", "previewNet", "previewTotalCost",
    "deductionsContainer"
  ]
  static values = { previewUrl: String }

  connect() {
    this.toggleSalaryFields()
  }

  toggleSalaryFields() {
    const isSalary = this.sourceTypeTarget.value === "salary"
    if (this.hasSalarySectionTarget) {
      this.salarySectionTarget.style.display = isSalary ? "" : "none"
    }
  }

  async calculate() {
    const gross = this.grossTarget.value
    if (!gross || gross <= 0) {
      if (this.hasPreviewTarget) this.previewTarget.style.display = "none"
      return
    }

    const url = `${this.previewUrlValue}?gross=${encodeURIComponent(gross)}`
    const response = await fetch(url, { headers: { Accept: "application/json" } })
    const data = await response.json()

    this.previewGrossTarget.textContent  = this.fmt(data.gross)
    this.previewCasTarget.textContent    = this.fmt(data.cas)
    this.previewCassTarget.textContent   = this.fmt(data.cass)
    this.previewIvTarget.textContent     = this.fmt(data.iv)
    this.previewCamTarget.textContent        = this.fmt(data.cam)
    this.previewNetTarget.textContent        = this.fmt(data.net)
    this.previewTotalCostTarget.textContent  = this.fmt(data.total_cost)

    if (this.hasNetAmountTarget) this.netAmountTarget.value  = data.net
    if (this.hasGrossAmountTarget) this.grossAmountTarget.value = data.total_cost

    this.fillDeductions(data)

    if (this.hasPreviewTarget) this.previewTarget.style.display = ""
  }

  fillDeductions(data) {
    if (!this.hasDeductionsContainerTarget) return
    this.deductionsContainerTarget.innerHTML = ""

    const deductions = [
      { name: "Asigurari Sociale (CAS)", amount: data.cas, percentage: 25.0, paid_by: "employee" },
      { name: "Asigurari Sociale de Sanatate (CASS)", amount: data.cass, percentage: 10.0, paid_by: "employee" },
      { name: "Impozit pe venit (IV)", amount: data.iv, percentage: 10.0, paid_by: "employee" },
      { name: "Contributie Asiguratorie pentru Munca (CAM)", amount: data.cam, percentage: 2.25, paid_by: "employer" }
    ]

    deductions.forEach((d, i) => {
      const row = document.createElement("div")
      row.className = "deduction-row"
      row.innerHTML = `
        <input type="text"   name="card_top_up[source_deductions_attributes][${i}][name]"       value="${d.name}"       class="form-control form-control-inline" placeholder="Name">
        <input type="number" name="card_top_up[source_deductions_attributes][${i}][amount]"     value="${d.amount}"     class="form-control form-control-inline" step="0.01" placeholder="Amount">
        <input type="number" name="card_top_up[source_deductions_attributes][${i}][percentage]" value="${d.percentage}" class="form-control form-control-inline" step="0.01" placeholder="%">
        <select name="card_top_up[source_deductions_attributes][${i}][paid_by]" class="form-control form-control-inline">
          <option value="employee" ${d.paid_by === "employee" ? "selected" : ""}>Employee</option>
          <option value="employer" ${d.paid_by === "employer" ? "selected" : ""}>Employer</option>
        </select>
        <button type="button" class="btn btn-sm btn-danger" data-action="click->salary-calculator#removeDeduction">✕</button>
      `
      this.deductionsContainerTarget.appendChild(row)
    })
  }

  addDeduction() {
    const existing = this.deductionsContainerTarget.querySelectorAll(".deduction-row").length
    const template = document.getElementById("deduction-template")
    const clone = template.content.cloneNode(true)
    clone.querySelectorAll("[name]").forEach(el => {
      el.name = el.name.replace("NEW_INDEX", existing)
    })
    this.deductionsContainerTarget.appendChild(clone)
  }

  removeDeduction(event) {
    const row = event.target.closest(".deduction-row")
    const destroyFlag = row.querySelector(".destroy-flag")
    if (destroyFlag) {
      destroyFlag.value = "1"
      row.style.display = "none"
    } else {
      row.remove()
    }
  }

  fmt(value) {
    return Number(value).toLocaleString("ro-RO", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }
}
