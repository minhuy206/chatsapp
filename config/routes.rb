Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # LLM Chat API routes
  namespace :api do
    namespace :v1 do
      post "chat", to: "chat#create"
      resources :conversations, only: [:index, :show]
      resources :models, only: [:index, :show], param: :name
      get "health", to: "health#show"
    end
  end
end
