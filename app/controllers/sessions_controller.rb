require "rqrcode"
require "erb"

class SessionsController < Devise::SessionsController
  include ERB::Util
  include AuthenticationBackend
  layout "full_width_layout"

  before_action :load_secret_code, only: %i(create new)
  before_action :challenge_flash_messages, only: %i(create new)

  def create
    if session[:challenge_parameters].nil?
      sign_in_form = SignInForm.new(params["user"])
      if sign_in_form.valid?
        super
      else
        flash[:errors] = sign_in_form.errors.full_messages.join(", ")
        redirect_to new_session_path(resource_name)
      end
    else
      super
    end
  end

  def destroy
    UserSignOutEvent.create(user_id: warden.user.user_id)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out
    yield if block_given?
    respond_to_on_destroy
  end

  def challenge_flash_messages
    return if session.to_h.dig("challenge_parameters", "flash_message").nil?

    msg = session.to_h.dig("challenge_parameters", "flash_message", "code")
    session[:challenge_parameters].delete("flash_message")
    set_flash_message! :warn, msg.to_sym, now: true
  end

  def load_secret_code
    generate_new_qr unless session[:secret_code].nil?
  end

private

  def generate_new_qr
    @secret_code = session[:secret_code]
    issuer = "GOV.UK Verify Admin Tool"
    issuer += " (#{Rails.env})" unless Rails.env.production?
    encoded_issuer = url_encode(issuer)
    qrcode = RQRCode::QRCode.new("otpauth://totp/#{encoded_issuer}:#{url_encode(session[:email])}?secret=#{@secret_code}&issuer=#{encoded_issuer}")
    @secret_code_svg = qrcode.as_svg(module_size: 3)
  end
end
