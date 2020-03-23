Rails.application.routes.draw do
  root to: 'units#index'

  # get 'teams/index'
  # get 'teams/show'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # resources :units, only: [:index, :show]

  get '/units' => 'units#index'
  get '/units/:team_id' => 'units#show_units'


  get '/units/utility_json' => 'units#utility_json'

  get '/teams' => 'teams#index'
  get '/teams/:id', to: 'teams#show'
  get '/power_scores', to: 'teams#powerScores'


  # sidekiq dashboard – localhost:3000/sidekiq
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  match '*path', to: 'units#index', via: :all
end
