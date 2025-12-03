Rails.application.routes.draw do
  # Authentication
  resource :session, only: %i[new create destroy]
  resources :users, only: %i[new create]

  # Profile / Username
  resource :username, only: %i[show create update]

  # Public user profiles
  get "user/:username", to: "profiles#show", as: :profile
  get "user/:username/visits", to: "profiles#visits", as: :profile_visits

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
