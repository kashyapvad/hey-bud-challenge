require 'sidekiq/web'
Rails.application.routes.draw do
  get 'sessions/new'
  get 'sessions/create'
  get 'sessions/destroy'
  get 'users/new'
  get 'users/create'
  mount Sidekiq::Web => '/sidekiq'

  resources :plans do end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root 'plans#new' # Replace with your root controller/action
  get "error" => "plans#error"

  # Defines the root path route ("/")
  # root "posts#index"

  get  'signup', to: 'users#new',      as: 'signup'
  post 'users',  to: 'users#create'

  get    'login',  to: 'sessions#new',     as: 'login'
  post   'login',  to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy', as: 'logout'

  # For API authentication in the future
  namespace :api do
    namespace :v1 do
      # Define your API routes here
    end
  end
end
