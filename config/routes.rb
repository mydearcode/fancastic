Rails.application.routes.draw do
  root "posts#index"
  resources :posts do
    member do
      post :like
      post :repost
      get :quote
      post :quote
    end
  end
  get "profile", to: "profiles#show"
  get "profile/edit", to: "profiles#edit"
  patch "profile", to: "profiles#update"
  get "users/:id", to: "profiles#show_user", as: :user_profile
  resource :session
  resources :registrations, only: [:new, :create]
  resources :passwords, param: :token
  
  # Messaging routes
  resources :conversations do
    resources :messages, only: [:create, :destroy]
  end
  post "conversations/start_with_user/:user_id", to: "conversations#start_with_user", as: :start_conversation_with_user
  
  # Admin routes
  namespace :admin do
    root "admin#index"
    resources :countries
    resources :leagues
    resources :teams
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")

end
