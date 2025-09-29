Rails.application.routes.draw do
  resource :session, only: [ :destroy ]
  resources :users, only: [ :new, :create ]
  resources :one_time_codes, only: [ :new, :create ]
  get "resend_code", to: "one_time_codes#resend", as: :resend_one_time_code

  # OAuth 2.0 / OpenID Connect endpoints
  get "oauth/authorize", to: "oauth#authorize"
  post "oauth/authorize", to: "oauth#consent"
  post "oauth/token", to: "oauth#token"
  get "oauth/userinfo", to: "oauth#userinfo"
  get "oauth/jwks", to: "oauth#jwks"
  get "oauth/callback", to: "oauth#callback"
  # Support clients configured with "/callback" as redirect_uri
  get "callback", to: "oauth#callback"

  # Visits API for map
  resources :visits, only: [ :index, :create, :destroy, :update ] do
    collection do
      get :export
      get :list
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
  get "start_oauth", to: "home#start_oauth"
end
