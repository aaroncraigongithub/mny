Rails.application.routes.draw do
  resources :scheduled_transactions

  resources :transactions

  resources :transaction_endpoints

  resources :accounts

  resources :categories

  devise_for :users

  get '/reports',   to: 'reports#index',      as: :reports
  get '/forecast',  to: 'forecast#index',     as: :forecast
  post '/forecast', to: 'forecast#forecast',  as: :do_forecast

  root to: "accounts#index"
end
