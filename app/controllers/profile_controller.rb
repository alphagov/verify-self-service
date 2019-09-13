class ProfileController < ApplicationController
  include AuthenticationBackend

  def show
    if Rails.env.development?
      @stub_available = true
      @using_stub = SelfService.service(:cognito_stub)
      @cognito_available = SelfService.service_present?(:real_client)
      @breakerofchains = @using_stub && current_user.given_name == 'Daenerys'
    end
    @user = current_user
  end

  def change_password
    passwd_form = params[:password_change]
    if passwd_form['new_password1'] != passwd_form['new_password2']
      flash[:notice] = t('profile.password_mismatch')
    else
      backend_change_password(
        old: passwd_form['old_password'],
        proposed: passwd_form['new_password1'],
        access_token: current_user.access_token
      )
      flash[:notice] = t('profile.password_changed')
    end
    redirect_to profile_path
  rescue InvalidOldPassowrdError
    flash[:warn] = t('profile.old_password_mismatch')
    redirect_to profile_path
  rescue InvalidNewPassowrdError
    flash[:warn] = t('devise.sessions.InvalidPasswordException')
    redirect_to profile_path
  rescue AuthenticationBackendException
    flash[:warn] = t('devise.failure.unknown_cognito_response')
    redirect_to profile_path
  end

  def switch_client
    if params[:client] == 'cognito'
      CognitoStubClient.switch_to_cognito
      flash[:notice] = 'Switched to Cognito Auth Client'
    elsif params[:client] == 'stub'
      CognitoStubClient.switch_to_stub
      flash[:notice] = 'Switched to Stub Auth Client'
    end
    redirect_to profile_path
  end

  def update_role
    if params[:assume_roles].nil?
      CognitoStubClient.update_user(role: "")
    else
      role_str = params[:assume_roles][:role_selection].join(',')
      if params[:assume_roles][:role_selection].include?(ROLE::GDS)
        CognitoStubClient.update_user(
          role: role_str, email_domain: TEAMS::GDS_EMAIL_DOMAIN
        )
      else
        CognitoStubClient.update_user(role: role_str)
      end
    end
    UserSignOutEvent.create(user_id: warden.user.user_id)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    flash[:notice] = 'You need to sign in again for role changes to take effect' if signed_out
    redirect_to root_path
  end
end
