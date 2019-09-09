require 'rqrcode'
require 'erb'
require 'auth/authentication_backend'

module ControllerConcern
  include ERB::Util
  include AuthenticationBackend
  extend ActiveSupport::Concern

  def component_key(params)
    params.keys.find { |m| m.include?('component_id') }
  end

  def component_name_from_params(params)
    key = component_key(params)
    key.gsub('_id', '').split('_').map(&:titleize).join
  end

  def generate_new_qr
    @secret_code = session[:secret_code] || associate_device(access_token: session[:access_token])
    issuer = "GOV.UK Verify Admin Tool"
    issuer += " (#{Rails.env})" unless Rails.env.production?
    encoded_issuer = url_encode(issuer)
    qrcode = RQRCode::QRCode.new("otpauth://totp/#{encoded_issuer}:#{url_encode(session[:email])}?secret=#{@secret_code}&issuer=#{encoded_issuer}")
    @secret_code_svg = qrcode.as_svg(module_size: 3)
  end
end
