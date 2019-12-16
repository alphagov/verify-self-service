require 'auth/authentication_backend'
require 'notify/notification'

class PasswordController < ApplicationController
  include AuthenticationBackend
  include Notification

  skip_before_action :authenticate_user!, except: %w[password_form update_password]
  skip_before_action :set_user, except: %w[password_form update_password]

  layout 'two_thirds_layout'

  def password_form
    @password_form = ChangePasswordForm.new
  end

  def update_password
    @password_form = ChangePasswordForm.new(params[:change_password_form] || {})
    if @password_form.valid?
      change_password(
        current_password: @password_form.old_password,
        new_password: @password_form.password,
        access_token: current_user.access_token,
      )
      send_changed_password_email(email_address: current_user.email, first_name: current_user.first_name)
      flash[:notice] = t('password.password_changed')
      redirect_to profile_path
    else
      render :password_form, status: :bad_request
    end
  rescue InvalidOldPasswordError
    flash[:error] = t('password.errors.old_password_mismatch')
    render :password_form, status: :bad_request
  rescue InvalidNewPasswordException
    flash[:error] = t('devise.sessions.InvalidPasswordException')
    render :password_form, status: :bad_request
  rescue AuthenticationBackendException
    flash[:error] = t('devise.failure.unknown_cognito_response')
    render :password_form, status: :bad_request
  end

  def forgot_form
    @form = ForgottenPasswordForm.new
  end

  def force_user_reset_password
    session[:email] = params[:email]
    request_password_reset(params)
    redirect_to reset_password_path(reset_by_admin: params[:reset_by_admin])
  end

  def send_code
    @form = ForgottenPasswordForm.new(params[:forgotten_password_form] || {})
    if @form.valid?
      session[:email] = @form.email
      request_password_reset(@form.to_h)
      redirect_to reset_password_path
    else
      flash.now[:errors] = @form.errors.full_messages.join(', ')
      render :forgot_form, status: :bad_request
    end
  end

  def user_code
    @form = PasswordRecoveryForm.new
  end

  def process_code
    if session[:email].nil? && params&.dig(:password_recovery_form, :email).nil?
      flash.now[:errors] = t('password.errors.email_missing')
      redirect_to forgot_password_path
    else
      @form = PasswordRecoveryForm.new(params[:password_recovery_form])
      @form.email = session[:email] if @form.email.nil?
      if @form.valid?
        reset_password(@form.to_h)
        send_changed_password_email(email_address: @form.email, first_name: get_user_by_email(email: @form.email).first_name)
        session.delete(:email)
        flash[:notice] = t('password.password_recovered')
        redirect_to new_user_session_path
      else
        flash.now[:errors] = @form.errors.full_messages.join(', ')
        render :user_code, status: :bad_request
      end
    end
  rescue UserNotFoundException
    session.delete(:email)
    redirect_to new_user_session_path
  rescue ExpiredConfirmationCodeException
    flash[:error] = t('password.errors.code_expired')
    redirect_to forgot_password_path
  rescue InvalidConfirmationCodeException
    flash[:error] = t('password.errors.code_invalid')
    render :user_code, status: :bad_request
  rescue InvalidNewPasswordException
    flash[:error] = t('password.errors.invalid_password')
    render :user_code, status: :bad_request
  end
end
