Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  get "/" => "pages#home"

  namespace :api do
    resources :train_stations, only: [:index, :show] do
      collection do
        get :search
      end
    end

    resources :trips, only: [:index, :show]
    resources :train_lines, only: [:index]
    resources :isochrones, only: [:index]
  end

  # Defines the root path route ("/")
  root "pages#home"
end
