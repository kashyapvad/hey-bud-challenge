require 'sidekiq/web'
Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "/" => "api/v1/restaurants#home"
  get "api/v1" => "api/v1/restaurants#home"
  get "api/v1/restaurants" => "api/v1/restaurants#index"
end