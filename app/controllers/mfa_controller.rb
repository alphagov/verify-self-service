require 'rqrcode'
require 'erb'

class MfaController < ApplicationController
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
      SelfService.service(:cognito_client).verify_software_token(
        access_token: session[:access_token],
        user_code: @form.code
      )
    rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
      Rails.logger.error e
      flash.now[:error] = t('mfa_enrolment.errors.generic_error')
      generate_new_qr
      return render :index, status: :bad_request
    end
    SelfService.service(:cognito_client).set_user_mfa_preference(
      access_token: session[:access_token],
      software_token_mfa_settings: {
        enabled: true,
        preferred_mfa: true
      }
    )
    flash.now[:success] = t('mfa_enrolment.success')
    redirect_to root_path
  end

private

  def generate_new_qr
    associate = SelfService.service(:cognito_client).associate_software_token(access_token: session[:access_token])
    @secret_code = associate.secret_code
    issuer = "GOV.UK Verify Admin Tool"
    issuer += " (#{Rails.env})" unless Rails.env.production?
    encoded_issuer = url_encode(issuer)
    qrcode = RQRCode::QRCode.new("otpauth://totp/#{encoded_issuer}:#{url_encode(session[:email])}?secret=#{@secret_code}&issuer=#{encoded_issuer}")
    @secret_code_svg = qrcode.as_svg(module_size: 3)
  end

  def enrolment_only
    redirect_to root_path if user_signed_in? || session[:access_token].nil?
  end
end
