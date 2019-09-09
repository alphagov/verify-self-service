require 'rqrcode'
require 'erb'

class SessionsController < Devise::SessionsController
  include ERB::Util
  before_action :generate_new_qr

  def destroy
    UserSignOutEvent.create(user_id: warden.user.user_id)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out
    yield if block_given?
    respond_to_on_destroy
  end

private

  def generate_new_qr
    return false if session[:secret_code].nil?

    @secret_code = session[:secret_code]
    issuer = 'GOV.UK Verify Admin Tool'
    issuer += " (#{Rails.env})" unless Rails.env.production?
    encoded_issuer = url_encode(issuer)
    qrcode = RQRCode::QRCode.new("otpauth://totp/#{encoded_issuer}:#{url_encode(session[:email])}?secret=#{@secret_code}&issuer=#{encoded_issuer}")
    @secret_code_svg = qrcode.as_svg(module_size: 3)
  end
end
