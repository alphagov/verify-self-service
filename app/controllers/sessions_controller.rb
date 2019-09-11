class SessionsController < Devise::SessionsController
  include ControllerConcern

  before_action :load_secret_code, only: %i(create new)
  before_action :challenge_flash_messages, only: %i(create new)

  def destroy
    UserSignOutEvent.create(user_id: warden.user.user_id)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out
    yield if block_given?
    respond_to_on_destroy
  end

  def challenge_flash_messages
    return false if session.to_h.dig('challenge_parameters', 'flash_message').nil?

    msg = session.to_h.dig('challenge_parameters', 'flash_message', 'devise_message')
    session[:challenge_parameters].delete('flash_message')
    set_flash_message! :warn, msg.to_sym, now: true
  end

  def load_secret_code
    return false if session[:secret_code].nil?

    generate_new_qr
  end
end
