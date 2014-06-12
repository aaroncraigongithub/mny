Rails.application.routes.draw do
  resources :scheduled_transactions

  resources :transactions

  resources :transaction_endpoints

  resources :accounts

  resources :categories

  devise_for :users

  root to: "home#index"
end
