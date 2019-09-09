require 'rqrcode'
require 'erb'
require 'auth/authentication_backend'

class MfaController < ApplicationController
  include ControllerConcern
  include AuthenticationBackend
  include ERB::Util
  skip_before_action :authenticate_user!
  skip_before_action :set_user

  before_action :enrolment_only

  def index
    @form = MfaEnrolmentForm.new({})
    generate_new_qr
  end

  def enrol
    @form = MfaEnrolmentForm.new(params[:mfa_enrolment_form] || {})
    begin
      enrol_totp_device(access_token: session[:access_token], totp_code: @form.code)
    rescue AuthenticationBackend::AuthenticationBackendException => e
      Rails.logger.error e
      flash.now[:error] = t('mfa_enrolment.errors.generic_error')
      generate_new_qr
      return render :index, status: :bad_request
    end
    flash.now[:success] = t('mfa_enrolment.success')
    redirect_to root_path
  end

private

  def enrolment_only
    redirect_to root_path if user_signed_in? || session[:access_token].nil?
  end
end
