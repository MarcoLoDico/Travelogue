Rails.application.routes.draw do
  # Authentication
  resource :session, only: %i[new create destroy]
  resources :users, only: %i[new create]

  # Username route removed - usernames are set at signup and cannot be changed

  # Visits API for map
  resources :visits, only: %i[index create destroy update] do
    collection do
      get :export
      get :list
    end
  end

  # Health check endpoint for load balancers and uptime monitors
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path
  root "home#index"
end
