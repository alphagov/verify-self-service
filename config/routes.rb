Rails.application.routes.draw do

  devise_for :users, controllers: {sessions: "sessions", registrations: "registrations"}
  
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

  if %w(test development).include? Rails.env

    # Profile Page
    get '/profile/', to: 'profile#show'
    get '/profile/edit', to: 'profile#edit'
    post '/profile/edit', to: 'profile#update'
  end

end
