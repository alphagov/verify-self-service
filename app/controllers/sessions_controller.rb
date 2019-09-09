require 'rqrcode'
require 'erb'

class SessionsController < Devise::SessionsController
  include ControllerConcern
  include ERB::Util
  before_action :load_secret_code, only: %i(create new)

  def destroy
    UserSignOutEvent.create(user_id: warden.user.user_id)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out
    yield if block_given?
    respond_to_on_destroy
  end

  def load_secret_code
    return false if session[:secret_code].nil?

    generate_new_qr
  end
end
