Rails.application.routes.draw do

  devise_for :users, controllers: {sessions: "sessions"}
  
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

  if %w(test development).include? Rails.env
    # Dashboard
    get 'profile', to: 'profile#show'
  end

end
