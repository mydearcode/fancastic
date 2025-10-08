Rails.application.routes.draw do
  # Search routes
  get "search", to: "search#index"
  get "search/index"
  
  resources :trends, only: [:index]
  get 'trend/:phrase', to: 'trends#show', as: :trend, constraints: { phrase: /[^\/]+/ }
  # Suspended account route
  get 'suspended_account(/:username)', to: 'suspended_accounts#show', as: :suspended_account
  resources :reports, only: [:new, :create]
  root "posts#index"
  
  # Post creation route
  resources :posts, only: [:create, :new]
  
  # Username-based post routes (new format)
  get '/:username/posts/:id', to: 'posts#show', as: :user_post,
      constraints: { username: /[a-zA-Z0-9_]{3,20}/ }
  post '/:username/posts/:id/like', to: 'posts#like', as: :like_user_post,
       constraints: { username: /[a-zA-Z0-9_]{3,20}/ }
  post '/:username/posts/:id/repost', to: 'posts#repost', as: :repost_user_post,
       constraints: { username: /[a-zA-Z0-9_]{3,20}/ }
  post '/:username/posts/:id/reply', to: 'posts#reply', as: :reply_user_post,
       constraints: { username: /[a-zA-Z0-9_]{3,20}/ }
  get '/:username/posts/:id/quote', to: 'posts#quote', as: :quote_user_post,
      constraints: { username: /[a-zA-Z0-9_]{3,20}/ }
  post '/:username/posts/:id/quote', to: 'posts#quote', as: :create_quote_user_post,
       constraints: { username: /[a-zA-Z0-9_]{3,20}/ }
  get '/:username/posts/:id/quotes', to: 'posts#quotes', as: :quotes_user_post,
      constraints: { username: /[a-zA-Z0-9_]{3,20}/ }

  # Legacy post routes with redirects to new username-based format
  resources :posts, only: [:show] do
    member do
      get '/', to: redirect { |params, request| 
        begin
          post = Post.find(params[:id])
          "/#{post.user.username}/posts/#{post.id}"
        rescue ActiveRecord::RecordNotFound
          "/posts"
        end
      }
      post :like, to: redirect { |params, request|
        begin
          post = Post.find(params[:id])
          "/#{post.user.username}/posts/#{post.id}/like"
        rescue ActiveRecord::RecordNotFound
          "/posts"
        end
      }
      post :repost, to: redirect { |params, request|
        begin
          post = Post.find(params[:id])
          "/#{post.user.username}/posts/#{post.id}/repost"
        rescue ActiveRecord::RecordNotFound
          "/posts"
        end
      }
      post :reply, to: redirect { |params, request|
        begin
          post = Post.find(params[:id])
          "/#{post.user.username}/posts/#{post.id}/reply"
        rescue ActiveRecord::RecordNotFound
          "/posts"
        end
      }
      get :quote, to: redirect { |params, request|
        begin
          post = Post.find(params[:id])
          "/#{post.user.username}/posts/#{post.id}/quote"
        rescue ActiveRecord::RecordNotFound
          "/posts"
        end
      }
      post :quote, to: redirect { |params, request|
        begin
          post = Post.find(params[:id])
          "/#{post.user.username}/posts/#{post.id}/quote"
        rescue ActiveRecord::RecordNotFound
          "/posts"
        end
      }
      get :quotes, to: redirect { |params, request|
        begin
          post = Post.find(params[:id])
          "/#{post.user.username}/posts/#{post.id}/quotes"
        rescue ActiveRecord::RecordNotFound
          "/posts"
        end
      }
    end
  end
  get "profile", to: "profiles#show"
  get "profile/edit", to: "profiles#edit"
  patch "profile", to: "profiles#update"
  
  # Legacy user profile route (redirect to new format)
  get "users/:id", to: "profiles#redirect_legacy_profile"
  
  # Notifications routes
  resources :notifications, only: [:index] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_as_read
    end
  end

  # Energy routes (user-facing)
  get "energy", to: "energy#index", as: :energy
  post "energy/claim", to: "energy#claim", as: :claim_energy

  # Settings routes
  get "settings", to: "settings#index"
  get "settings/blocked_users", to: "settings#blocked_users"
  get "settings/privacy", to: "settings#privacy"
  get "settings/notifications", to: "settings#notifications"
  
  # Block routes only - follow routes moved to username-based routing
  resources :users, only: [] do
    # Block routes
    post :block, to: "blocks#create"
    delete :block, to: "blocks#destroy", as: :unblock
  end
  
  # Blocked users list
  resources :blocks, only: [:index]
  
  resource :session
  resources :registrations, only: [:new, :create]
  resources :passwords, param: :token
  
  # Email verification routes
  resources :email_verifications, only: [:new, :create]
  get 'verify_email/:token', to: 'email_verifications#show', as: :verify_email
  
  # Messaging routes
  resources :conversations do
    resources :messages, only: [:create, :destroy]
  end
  post "conversations/start_with_user/:user_id", to: "conversations#start_with_user", as: :start_conversation_with_user
  
  # Admin routes
  namespace :admin do
    root to: "admin#index"
    resources :countries
    resources :leagues
    resources :teams
    resources :reports, only: [:index, :destroy, :update]
    resources :posts, only: [:index, :destroy] do
      member do
        patch :restore
      end
    end
    resources :users, only: [:index] do
      collection do
        get :search
        get :suspension_logs
      end
      member do
        patch :suspend
        patch :unsuspend
      end
    end
    resources :suspended_users, only: [:index] do
      member do
        patch :unsuspend
      end
    end
    
    # Energy management routes
    resources :energy, only: [:index, :show] do
      member do
        patch :update_user_energy
      end
      collection do
        get :energy_costs
        patch :update_energy_costs
        post :bulk_energy_restore
      end
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
  
  # API routes
  namespace :api do
    resources :users, only: [:show], param: :username
  end
  
  # Mount ActionCable server
  mount ActionCable.server => '/cable'
  
  # User profile friendly URLs (must be at the end to avoid conflicts)
  get '/:username', to: 'profiles#show_user', as: :user_profile, 
      constraints: { username: /[a-zA-Z0-9_]{3,20}/ }
  get '/:username/follows', to: 'follows#index', as: :user_follows,
      constraints: { username: /[a-zA-Z0-9_]{3,20}/ }
  get '/:username/followers', to: 'follows#followers', as: :user_followers,
      constraints: { username: /[a-zA-Z0-9_]{3,20}/ }
  get '/:username/following', to: 'follows#following', as: :user_following,
      constraints: { username: /[a-zA-Z0-9_]{3,20}/ }
  
  # Username-based follow routes
  post '/:username/follow', to: 'follows#create', as: :user_follow,
       constraints: { username: /[a-zA-Z0-9_]{3,20}/ }
  delete '/:username/follow', to: 'follows#destroy', as: :user_unfollow,
         constraints: { username: /[a-zA-Z0-9_]{3,20}/ }

end
