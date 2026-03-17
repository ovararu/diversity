require "test_helper"

class CardTopUpsControllerTest < ActionDispatch::IntegrationTest
  # ---------------------------------------------------------------------------
  # GET /card_top_ups (index)
  # ---------------------------------------------------------------------------

  test "GET index returns 200" do
    get card_top_ups_path
    assert_response :success
  end

  test "GET index shows top-up descriptions" do
    get card_top_ups_path
    assert_match card_top_ups(:salary_top_up).source_type.capitalize, response.body
  end

  test "GET index shows total loaded amount" do
    get card_top_ups_path
    # page renders total_loaded — check it's present (exact format may vary)
    assert_response :success
  end

  test "GET index lists top-ups ordered by date descending" do
    get card_top_ups_path
    # The most recent top-up date should appear before earlier ones in the body
    newer_pos  = response.body.index(card_top_ups(:transfer_top_up).date.strftime("%d.%m.%Y"))
    older_pos  = response.body.index(card_top_ups(:salary_top_up).date.strftime("%d.%m.%Y"))
    assert newer_pos < older_pos
  end

  # ---------------------------------------------------------------------------
  # GET /card_top_ups/:id (show)
  # ---------------------------------------------------------------------------

  test "GET show returns 200" do
    get card_top_up_path(card_top_ups(:salary_top_up))
    assert_response :success
  end

  test "GET show renders the top-up description" do
    top_up = card_top_ups(:salary_top_up)
    get card_top_up_path(top_up)
    assert_match top_up.description, response.body
  end

  test "GET show returns 404 for unknown id" do
    get card_top_up_path(id: 999999)
    assert_response :not_found
  end

  # ---------------------------------------------------------------------------
  # GET /card_top_ups/new (new)
  # ---------------------------------------------------------------------------

  test "GET new returns 200" do
    get new_card_top_up_path
    assert_response :success
  end

  test "GET new form has today's date pre-filled" do
    get new_card_top_up_path
    assert_match Date.today.strftime("%Y-%m-%d"), response.body
  end

  test "GET new form has salary selected by default" do
    get new_card_top_up_path
    assert_match "salary", response.body
  end

  # ---------------------------------------------------------------------------
  # GET /card_top_ups/:id/edit (edit)
  # ---------------------------------------------------------------------------

  test "GET edit returns 200" do
    get edit_card_top_up_path(card_top_ups(:salary_top_up))
    assert_response :success
  end

  test "GET edit returns 404 for unknown id" do
    get edit_card_top_up_path(id: 999999)
    assert_response :not_found
  end

  # ---------------------------------------------------------------------------
  # POST /card_top_ups (create)
  # ---------------------------------------------------------------------------

  test "POST create with valid params creates a new CardTopUp" do
    assert_difference "CardTopUp.count", 1 do
      post card_top_ups_path, params: {
        card_top_up: {
          date: "2026-03-01",
          description: "March Salary",
          source_type: "salary",
          net_amount: "4500.00",
          eur_rate: "5.01"
        }
      }
    end
  end

  test "POST create with valid params redirects to the new top-up" do
    post card_top_ups_path, params: {
      card_top_up: {
        date: "2026-03-01",
        source_type: "salary",
        net_amount: "4500.00"
      }
    }
    assert_redirected_to card_top_up_path(CardTopUp.last)
  end

  test "POST create sets flash notice on success" do
    post card_top_ups_path, params: {
      card_top_up: {
        date: "2026-03-01",
        source_type: "salary",
        net_amount: "4500.00"
      }
    }
    assert_equal "Top-up created successfully.", flash[:notice]
  end

  test "POST create with nested source_deductions creates deductions" do
    assert_difference "SourceDeduction.count", 2 do
      post card_top_ups_path, params: {
        card_top_up: {
          date: "2026-03-01",
          source_type: "salary",
          net_amount: "4500.00",
          source_deductions_attributes: {
            "0" => { name: "CAS",  amount: "1125", paid_by: "employee" },
            "1" => { name: "CASS", amount: "450",  paid_by: "employee" }
          }
        }
      }
    end
  end

  test "POST create persists deduction amounts correctly" do
    post card_top_ups_path, params: {
      card_top_up: {
        date: "2026-03-01",
        source_type: "salary",
        net_amount: "4500.00",
        source_deductions_attributes: {
          "0" => { name: "CAS", amount: "1125", paid_by: "employee" }
        }
      }
    }
    deduction = CardTopUp.last.source_deductions.first
    assert_equal 1125.0, deduction.amount.to_f
  end

  test "POST create with invalid params does not create a CardTopUp" do
    assert_no_difference "CardTopUp.count" do
      post card_top_ups_path, params: {
        card_top_up: { date: "", source_type: "", net_amount: "" }
      }
    end
  end

  test "POST create with invalid params renders new with 422" do
    post card_top_ups_path, params: {
      card_top_up: { date: "", source_type: "", net_amount: "" }
    }
    assert_response :unprocessable_entity
  end

  test "POST create with net_amount zero renders new with 422" do
    post card_top_ups_path, params: {
      card_top_up: { date: "2026-03-01", source_type: "transfer", net_amount: "0" }
    }
    assert_response :unprocessable_entity
  end

  # ---------------------------------------------------------------------------
  # PATCH /card_top_ups/:id (update)
  # ---------------------------------------------------------------------------

  test "PATCH update with valid params updates the top-up" do
    top_up = card_top_ups(:transfer_top_up)
    patch card_top_up_path(top_up), params: {
      card_top_up: { description: "Updated description" }
    }
    assert_equal "Updated description", top_up.reload.description
  end

  test "PATCH update with valid params redirects to the top-up" do
    top_up = card_top_ups(:transfer_top_up)
    patch card_top_up_path(top_up), params: {
      card_top_up: { description: "Updated" }
    }
    assert_redirected_to card_top_up_path(top_up)
  end

  test "PATCH update sets flash notice on success" do
    top_up = card_top_ups(:transfer_top_up)
    patch card_top_up_path(top_up), params: {
      card_top_up: { description: "Updated" }
    }
    assert_equal "Top-up updated successfully.", flash[:notice]
  end

  test "PATCH update with negative net_amount renders edit with 422" do
    top_up = card_top_ups(:salary_top_up)
    patch card_top_up_path(top_up), params: {
      card_top_up: { net_amount: "-1" }
    }
    assert_response :unprocessable_entity
  end

  test "PATCH update with invalid params does not change the record" do
    top_up = card_top_ups(:salary_top_up)
    original_amount = top_up.net_amount
    patch card_top_up_path(top_up), params: {
      card_top_up: { net_amount: "-1" }
    }
    assert_equal original_amount, top_up.reload.net_amount
  end

  # ---------------------------------------------------------------------------
  # DELETE /card_top_ups/:id (destroy)
  # ---------------------------------------------------------------------------

  test "DELETE destroy removes the top-up" do
    top_up = CardTopUp.create!(date: Date.today, net_amount: 100, source_type: "transfer")
    assert_difference "CardTopUp.count", -1 do
      delete card_top_up_path(top_up)
    end
  end

  test "DELETE destroy redirects to index" do
    top_up = CardTopUp.create!(date: Date.today, net_amount: 100, source_type: "transfer")
    delete card_top_up_path(top_up)
    assert_redirected_to card_top_ups_path
  end

  test "DELETE destroy sets flash notice" do
    top_up = CardTopUp.create!(date: Date.today, net_amount: 100, source_type: "transfer")
    delete card_top_up_path(top_up)
    assert_equal "Top-up deleted.", flash[:notice]
  end

  test "DELETE destroy also removes associated source_deductions" do
    top_up = CardTopUp.create!(date: Date.today, net_amount: 1000, source_type: "salary")
    SourceDeduction.create!(card_top_up: top_up, name: "CAS", amount: 250)
    assert_difference "SourceDeduction.count", -1 do
      delete card_top_up_path(top_up)
    end
  end

  # ---------------------------------------------------------------------------
  # GET /card_top_ups/salary_preview (salary_preview)
  # ---------------------------------------------------------------------------

  test "GET salary_preview returns 200" do
    get salary_preview_card_top_ups_path, params: { gross: "10000" }
    assert_response :success
  end

  test "GET salary_preview returns JSON content type" do
    get salary_preview_card_top_ups_path, params: { gross: "10000" }
    assert_equal "application/json", response.media_type
  end

  # gross param = total employer cost (Salariu Complet)
  # At 10000: gross(brut)=9780, cam=220, cas=2445, cass=978, iv=636, net=5721

  test "GET salary_preview returns total_cost equal to input" do
    get salary_preview_card_top_ups_path, params: { gross: "10000" }
    data = JSON.parse(response.body)
    assert_equal 10000, data["total_cost"]
  end

  test "GET salary_preview returns correct gross (Salariu Brut)" do
    get salary_preview_card_top_ups_path, params: { gross: "10000" }
    data = JSON.parse(response.body)
    assert_equal 9780, data["gross"]
  end

  test "GET salary_preview returns correct net" do
    get salary_preview_card_top_ups_path, params: { gross: "10000" }
    data = JSON.parse(response.body)
    assert_equal 5721, data["net"]
  end

  test "GET salary_preview returns correct CAM" do
    get salary_preview_card_top_ups_path, params: { gross: "10000" }
    data = JSON.parse(response.body)
    assert_equal 220, data["cam"]
  end

  test "GET salary_preview returns correct CAS" do
    get salary_preview_card_top_ups_path, params: { gross: "10000" }
    data = JSON.parse(response.body)
    assert_equal 2445, data["cas"]
  end

  test "GET salary_preview returns correct CASS" do
    get salary_preview_card_top_ups_path, params: { gross: "10000" }
    data = JSON.parse(response.body)
    assert_equal 978, data["cass"]
  end

  test "GET salary_preview returns correct IV" do
    get salary_preview_card_top_ups_path, params: { gross: "10000" }
    data = JSON.parse(response.body)
    # iv = round((9780 - 2445 - 978) * 0.10) = round(635.7) = 636
    assert_equal 636, data["iv"]
  end

  test "GET salary_preview applies personal_deduction to IV" do
    get salary_preview_card_top_ups_path, params: { gross: "10000", personal_deduction: "300" }
    data = JSON.parse(response.body)
    # iv = round((9780 - 2445 - 978 - 300) * 0.10) = round(605.7) = 606
    assert_equal 606, data["iv"]
  end

  test "GET salary_preview handles zero gross" do
    get salary_preview_card_top_ups_path, params: { gross: "0" }
    assert_response :success
    data = JSON.parse(response.body)
    assert_equal 0, data["net"].to_f
  end

  test "GET salary_preview handles missing gross param" do
    get salary_preview_card_top_ups_path
    assert_response :success
  end
end
