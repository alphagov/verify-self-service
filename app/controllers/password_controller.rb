require "auth/authentication_backend"

class PasswordController < ApplicationController
  include AuthenticationBackend

  skip_before_action :authenticate_user!, except: %w[password_form update_password]
  skip_before_action :set_user, except: %w[password_form update_password]

  layout "main_layout", only: :password_form

  def password_form
    @password_form = ChangePasswordForm.new
  end

  def update_password
    @password_form = ChangePasswordForm.new(params[:change_password_form])
    if @password_form.valid?
      change_password(
        current_password: @password_form.old_password,
        new_password: @password_form.password,
        access_token: current_user.access_token,
      )
      flash[:notice] = t("password.password_changed")
      redirect_to profile_path
    else
      flash.now[:errors] = @password_form.errors.full_messages.join(", ")
      render :password_form, status: :bad_request
    end
  rescue InvalidOldPasswordError
    flash[:error] = t("password.errors.old_password_mismatch")
    render :password_form, status: :bad_request
  rescue InvalidNewPasswordError
    flash[:error] = t("devise.sessions.InvalidPasswordException")
    render :password_form, status: :bad_request
  rescue AuthenticationBackendException
    flash[:error] = t("devise.failure.unknown_cognito_response")
    render :password_form, status: :bad_request
  end

  def forgot_form
    @form = ForgottenPasswordForm.new
  end

  def send_code
    @form = ForgottenPasswordForm.new(params[:forgotten_password_form])
    if @form.valid?
      request_password_reset(@form.to_h)
      session[:email] = @form.email
      @form = PasswordRecoveryForm.new
      render :user_code
    else
      flash.now[:errors] = @form.errors.full_messages.join(", ")
      render :forgot_form, status: :bad_request
    end
  rescue TooManyAttemptsError, UserBadStateError, UserGroupNotFoundException
    @form = PasswordRecoveryForm.new
    render :user_code
  end

  def user_code
    @form = PasswordRecoveryForm.new
    @email = session[:email]
  end

  def process_code
    if session[:email].nil? && params[:password_recovery_form][:email].nil?
      flash.now[:errors] = t("email_missing")
      render :forgot_form, status: :bad_request
    else
      @form = PasswordRecoveryForm.new(params[:password_recovery_form])
      @form.email = session[:email] if @form.email.nil?
      if @form.valid?
        reset_password(@form.to_h)
        session.delete(:email)
        flash[:notice] = t("password.password_recovered")
        redirect_to new_user_session_path
      else
        flash.now[:errors] = @form.errors.full_messages.join(", ")
        render :user_code, status: :bad_request
      end
    end
  rescue NotAuthorizedException, UserGroupNotFoundException
    redirect_to new_user_session_path
  end
end
