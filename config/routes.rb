Rails.application.routes.draw do

  devise_for :users
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
    # Dashboard
    get 'dashboard' =>'dashboard#show'
  end
end
