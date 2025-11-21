Rails.application.routes.draw do
  # API routes under /api/v1 namespace
  namespace :api do
    namespace :v1 do
      resources :payments, defaults: { format: :json }
      resources :matches, defaults: { format: :json }
      resources :athletes, defaults: { format: :json }
      resources :expenses, defaults: { format: :json }
      resources :incomes, defaults: { format: :json }
    end
  end

  # Legacy routes (keep for backward compatibility)
  resources :payments
  resources :matches
  resources :athletes
  resources :expenses
  resources :incomes
  get "dashboard", to: "dashboard#index"

  get "up" => "rails/health#show", as: :rails_health_check

  # Standardized health check endpoints for microservices
  get "health", to: "health#health"
  get "ready", to: "health#ready"

  root "dashboard#index"
end
