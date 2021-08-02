Rails.application.routes.draw do
  resources :teams, path: 'admin/teams'
  resources :services, path: 'admin/services'

  devise_for :users, controllers: { sessions: 'sessions' }

  root 'user_journey#index'

  get '/healthcheck', to: 'healthcheck#index'

  get '/admin', to: 'admin#index'
  get '/admin/publish-metadata/:environment', to: 'admin#publish_metadata', as: :publish_metadata

  resources :sp_components, path: 'admin/sp-components' do
    patch 'associate_service'
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
    patch 'associate_service'
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
  get '/users/:user_id/resend-invitation', to: 'users#resend_invitation', as: :resend_invitation
  get '/users/:user_id/update-email', to: 'users#show_update_email', as: :update_user_email_address
  post '/users/:user_id/update-email', to: 'users#update_email', as: :update_user_email_address_post
  get '/users/:user_id/remove-user', to: 'users#show_remove_user', as: :remove_user
  delete '/users/:user_id/remove-user', to: 'users#remove_user', as: :remove_user_post
  get '/users/:user_id/reset-user-password', to: 'users#show_reset_user_password', as: :reset_user_password
  post '/users/:user_id/reset-user-password', to: 'users#reset_user_password', as: :reset_user_password_post
  get '/users/emails-csv', to: 'users#emails_csv', as: :emails_csv

  get '/profile/change-password', to: 'password#password_form'
  post '/profile/change-password', to: 'password#update_password'
  get '/profile/update-name', to: 'profile#show_update_name', as: :update_user_name
  post '/profile/update-name', to: 'profile#update_name', as: :update_user_name_post
  get '/profile/setup-mfa', to: 'profile#setup_mfa', as: :setup_mfa
  get '/profile/update-mfa/new-code', to: 'profile#request_new_code', as: :request_new_code
  get '/profile/update-mfa', to: 'profile#warn_mfa'
  get '/profile/update-mfa/get-code', to: 'profile#show_change_mfa'
  post '/profile/update-mfa', to: 'profile#change_mfa', as: :update_mfa_post
  get '/support', to: 'support#index', as: :support
  get 'forgot-password', to: 'password#forgot_form'
  post 'forgot-password', to: 'password#send_code'
  get 'reset-password(/:reset_by_admin)', to: 'password#user_code', as: :reset_password
  post 'reset-password(/:reset_by_admin)', to: 'password#process_code'
  get 'reset-user-password/:email(/:reset_by_admin)', constraints: { email: /[^\/]+/}, to: 'password#force_user_reset_password', as: :force_user_reset_password

  get 'profile', to: 'profile#show'
  post 'profile/switch-client', to: 'profile#switch_client'
  post 'profile/update-role', to: 'profile#update_role'

  get '/rotate/:certificate_id', to: 'user_journey#view_certificate', as: 'view_certificate'
  patch '/rotate/:certificate_id/disable', to: 'user_journey#disable_certificate', as: 'disable_certificate'
  get '/rotate/:certificate_id/dual-running', to: 'user_journey#dual_running', as: 'dual_running'
  get '/rotate/:certificate_id/is-dual-running', to: 'user_journey#is_dual_running', as: 'is_dual_running'
  get '/rotate/:certificate_id/before-you-start(/:dual_running)', to: 'user_journey#before_you_start', as: 'before_you_start'
  get '/rotate/:certificate_id/upload-certificate(/:dual_running)', to: 'user_journey#upload_certificate', as: 'upload_certificate'
  get '/rotate/:certificate_id/check-your-certificate(/:dual_running)', to: 'user_journey#upload_certificate', as: 'check_your_certificate'
  post '/rotate/:certificate_id/check-your-certificate(/:dual_running)', to: 'user_journey#submit', as: 'submit'
  get '/rotate/:certificate_id/confirmation(/:dual_running)', to: 'user_journey#confirmation', as: 'confirmation'
  post '/rotate/:certificate_id/confirmation(/:dual_running)', to: 'user_journey#confirm', as: 'confirm'

  get '/cookies', to: 'static#cookies'
  get '/privacy-notice', to: 'static#privacy'

  devise_scope :user do
    get '/users/cancel' => "sessions#cancel", as: :cancel
  end
end
