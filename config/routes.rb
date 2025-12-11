Rails.application.routes.draw do
  # Scope routes with locale parameter
  # This allows URLs like /en/users or /es/users
  # The locale is optional and defaults to the configured default locale
  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    devise_for :users, controllers: { sessions: 'users/sessions', registrations: 'users/registrations' }
    
    # Custom account settings routes
    resource :account_settings, only: [:show] do
      member do
        patch :update_avatar
        patch :update_bio
        patch :update_username_email
        patch :update_password
        delete :delete_avatar
        delete :destroy
      end
    end
    root to: "pages#home"
    resources :tags, except: [:show]
    resources :tools do
      resources :comments, only: [:create, :destroy] do
        patch :resolve, on: :member
        post :upvote, on: :member
      end
      post :add_tag, on: :member
      delete :remove_tag, on: :member
      post :upvote, on: :member, to: "tools#upvote"
      post :favorite, on: :member, to: "tools#favorite"
      post :follow, on: :member, to: "tools#follow"
    end
    # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

    # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
    # Can be used by load balancers and uptime monitors to verify that the app is live.
    get "up" => "rails/health#show", as: :rails_health_check

    # Defines the root path route ("/")
    # root "posts#index"
    get "profile" => "profiles#show", as: :profile

    resources :lists
  end
end
