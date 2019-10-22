require 'rqrcode'
require 'erb'

module MfaQrHelper
  include ERB::Util
  include AuthenticationBackend

  def generate_new_qr(secret_code:, email:)
    issuer = "GOV.UK Verify Admin Tool"
    issuer += " (#{Rails.env})" unless Rails.env.production?
    encoded_issuer = url_encode(issuer)
    qrcode = RQRCode::QRCode.new("otpauth://totp/#{encoded_issuer}:#{url_encode(email)}?secret=#{secret_code}&issuer=#{encoded_issuer}")
    qrcode.as_svg(module_size: 3)
  end
end
