Rails.application.routes.draw do

  devise_for :users, controllers: {sessions: "sessions"}
  
  root 'components#index'
  resources :sp_components, path: 'sp-components' do
    resources :services
    resources :certificates do
      member do
        patch 'enable'
        patch 'disable'
        patch 'replace'
      end
    end
  end

  resources :msa_components, path: 'msa-components' do
    resources :services
    resources :certificates do
      member do
        patch 'enable'
        patch 'disable'
        patch 'replace'
      end
    end
  end

  get '/events', to: 'events#index'
  get '/events/:page', to: 'events#page'

  get '/users', to: 'users#index', as: :users
  get '/users/invite', to: 'users#invite', as: :invite_user
  post '/users/invite', to: 'users#new', as: :invite_new_user

  if %w(test development).include? Rails.env
    # Dashboard
    get 'profile', to: 'profile#show'
  end

end
