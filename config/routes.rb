Rails.application.routes.draw do

  namespace :admin do
    resources :teams, only: %i[index new create]
  end

  devise_for :users, controllers: { sessions: 'sessions' }

  root 'components#index'

  get '/admin', to: 'components#index'

  resources :sp_components, path: 'admin/sp-components' do
    resources :services
    resources :certificates do
      member do
        patch 'enable'
        patch 'disable'
        patch 'replace'
      end
    end
  end

  resources :msa_components, path: 'admin/msa-components' do
    resources :services
    resources :certificates do
      member do
        patch 'enable'
        patch 'disable'
        patch 'replace'
      end
    end
  end

  get '/admin/events', to: 'events#index'
  get '/admin/events/:page', to: 'events#page'

  get '/users', to: 'users#index', as: :users
  get '/users/invite', to: 'users#invite', as: :invite_user
  post '/users/invite', to: 'users#new', as: :invite_new_user

  if %w(test development).include? Rails.env
    # Dashboard
    get 'profile', to: 'profile#show'
  end
end
