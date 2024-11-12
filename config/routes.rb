Rails.application.routes.draw do
  Spree::User.class_eval do
    devise :omniauthable
  end
  
  Spree::Core::Engine.add_routes do
    devise_for :spree_user,
              class_name: Spree::User,
              only: [:omniauth_callbacks],
              controllers: { omniauth_callbacks: 'spree/omniauth_callbacks' },
              path: "users"
    resources :user_authentications

    get 'account' => 'users#show', as: 'user_root'

    namespace :admin do
      resources :authentication_methods
    end
  end
end