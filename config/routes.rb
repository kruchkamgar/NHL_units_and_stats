Rails.application.routes.draw do
  get 'teams/index'
  get 'teams/show'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :units, only: [:index, :show]

end
