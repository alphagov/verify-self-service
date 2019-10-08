Rails.application.routes.draw do
  resources :teams, path: 'admin/teams', only: %i[index new create]

  devise_for :users, controllers: { sessions: 'sessions' }

  root 'user_journey#index'

  get '/healthcheck', to: 'healthcheck#index'

  get '/admin', to: 'admin#index'

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
  get '/users/team/:team_id', to: 'users#index', as: :admin_users
  get '/users/team/:team_id/invite', to: 'users#invite', as: :invite_to_team
  post '/users/team/:team_id/invite', to: 'users#new', as: :invite_to_team_post
  get '/users/:user_id/update', to: 'users#show', as: :update_user
  post '/users/:user_id/update', to: 'users#update', as: :update_user_post
  get '/users/:user_id/update-email', to: 'users#show_update_email', as: :update_user_email_address
  post '/users/:user_id/update-email', to: 'users#update_email', as: :update_user_email_address_post
  get '/users/:user_id/update-email/email-verification-code', to: 'users#show_update_email_verification_code', as: :show_update_email_verification_code
  post '/users/:user_id/update-email/email-verification-code', to: 'users#update_email_verification_code', as: :update_email_verification_code_post


  get '/mfa-enrolment', to: 'mfa#index', as: :mfa_enrolment
  post '/mfa-enrolment', to: 'mfa#enrol', as: :enrol_to_mfa

  get '/profile/change-password', to: 'password#password_form'
  post '/profile/change-password', to: 'password#update_password'
  get 'forgot-password', to: 'password#forgot_form'
  post 'forgot-password', to: 'password#send_code'
  get 'reset-password', to: 'password#user_code'
  post 'reset-password', to: 'password#process_code'

  get 'profile', to: 'profile#show'
  post 'profile/switch-client', to: 'profile#switch_client'
  post 'profile/update-role', to: 'profile#update_role'

  get '/component/:component_type/:component_id/certificate/:certificate_id', to: 'user_journey#view_certificate', as: 'view_certificate'
  get '/component/:component_type/:component_id/certificate/:certificate_id/before-you-start', to: 'user_journey#before_you_start', as: 'before_you_start'
  get '/component/:component_type/:component_id/certificate/:certificate_id/upload-certificate', to: 'user_journey#upload_certificate', as: 'upload_certificate'
  get '/component/:component_type/:component_id/certificate/:certificate_id/check-your-certificate', to: 'user_journey#upload_certificate', as: 'check_your_certificate'
  post '/component/:component_type/:component_id/certificate/:certificate_id/check-your-certificate', to: 'user_journey#submit', as: 'submit'
  get '/component/:component_type/:component_id/certificate/:certificate_id/confirmation', to: 'user_journey#confirmation', as: 'confirmation'
  post '/component/:component_type/:component_id/certificate/:certificate_id/confirmation', to: 'user_journey#confirm', as: 'confirm'

  get '/cookies', to: 'static#cookies'

  devise_scope :user do
    get '/users/cancel' => "sessions#cancel", as: :cancel
  end
end
