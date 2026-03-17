Rails.application.routes.draw do
  root "card_top_ups#index"

  resources :card_top_ups do
    collection { get :salary_preview }
  end

  resources :expenses

  get "up" => "rails/health#show", as: :rails_health_check
end
