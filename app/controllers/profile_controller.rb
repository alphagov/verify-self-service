require 'notify/notification'

class ProfileController < ApplicationController
  layout "two_thirds_layout", except: :show
  include AuthenticationBackend
  include MfaQrHelper
  include Notification

  def show
    if Rails.env.development?
      @using_stub = SelfService.service(:cognito_stub)
      @cognito_available = SelfService.service_present?(:real_client)
    end
    updated_user = get_user_info(access_token: current_user.access_token)
    refresh_user(updated_user)
    @user = current_user
    @mfa_status = updated_user.preferred_mfa_setting
  end

  def switch_client
    case params[:client]
    when 'cognito'
      CognitoStubClient.switch_to_cognito
      flash[:notice] = 'Switched to Cognito Auth Client'
    when 'stub'
      CognitoStubClient.switch_to_stub
      flash[:notice] = 'Switched to Stub Auth Client'
    end
    redirect_to profile_path
  end

  def update_role
    if params[:assume_roles].nil?
      CognitoStubClient.update_user(role: '')
    else
      role_str = params[:assume_roles][:role_selection].join(',')
      if params[:assume_roles][:role_selection].include?(ROLE::GDS)
        CognitoStubClient.update_user(
          role: role_str, email_domain: TEAMS::GDS_EMAIL_DOMAIN,
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

  def setup_mfa
    if set_mfa_preferences(access_token: current_user.access_token)
      flash[:notice] = t('profile.mfa_setup_correctly')
      redirect_to profile_path
    else
      redirect_to profile_update_mfa_path
    end
  end

  def show_change_mfa
    @form = MfaEnrolmentForm.new({})
    @secret_code = session[:secret_code] || associate_device(access_token: current_user.access_token)
    @secret_code_svg = generate_new_qr(secret_code: @secret_code, email: current_user.email)
    flash[:secret_code] = @secret_code
  end

  def warn_mfa; end

  def request_new_code
    @form = MfaEnrolmentForm.new({})
    @secret_code = associate_device(access_token: current_user.access_token)
    @secret_code_svg = generate_new_qr(secret_code: @secret_code, email: current_user.email)
    flash[:secret_code] = @secret_code
    render :show_change_mfa
  end

  def change_mfa
    @form = MfaEnrolmentForm.new(params[:mfa_enrolment_form] || {})
    if @form.valid?
      verify_code_for_mfa(access_token: current_user.access_token, code: @form.totp_code)
      send_changed_mfa_email(email_address: current_user.email, first_name: current_user.first_name)
      flash[:sucess] = t('profile.mfa_success')
      redirect_to profile_path
    else
      mfa_page_erros
    end
  rescue InvalidConfirmationCodeException
    mfa_page_erros
  end

  def show_update_name
    updated_user = get_user_info(access_token: current_user.access_token)
    refresh_user(updated_user)
    @user = current_user
    @form = UpdateUserNameForm.new(first_name: @user.first_name, last_name: @user.last_name)
  end

  def update_name
    @form = UpdateUserNameForm.new(params[:update_user_name_form] || {})
    if @form.valid?
      update_user_name(access_token: current_user.access_token, given_name: @form.first_name, family_name: @form.last_name)
      UpdateUserNameEvent.create(data: { first_name: @form.first_name, last_name: @form.last_name })
      send_changed_name_email(email_address: current_user.email, new_name: "#{@form.first_name} #{@form.last_name}")
      redirect_to profile_path
    else
      @user = current_user
      render :show_update_name, status: :bad_request
    end
  rescue AuthenticationBackend::AuthenticationBackendException
    @user = current_user
    @form.errors.add(:base, t('users.update_name.errors.generic_error'))
    render :show_update_name, status: :bad_request
  end

private

  def mfa_page_erros
    flash[:retry] = true
    @secret_code = flash.discard[:secret_code]
    @secret_code_svg = generate_new_qr(secret_code: @secret_code, email: current_user.email)
    render :show_change_mfa, status: :bad_request
  end

  def refresh_user(updated_user)
    current_user.first_name = updated_user.user_attributes.find { |attr| attr.name == 'given_name' }.value
    current_user.last_name = updated_user.user_attributes.find { |attr| attr.name == 'family_name' }.value
    current_user.email = updated_user.user_attributes.find { |attr| attr.name == 'email' }.value
  end
end
