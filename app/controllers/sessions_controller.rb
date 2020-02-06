class SessionsController < Devise::SessionsController
  include MfaQrHelper

  layout 'full_width_layout'

  before_action :load_secret_code, only: %i(create new)
  before_action :challenge_flash_messages, only: %i(create new)

  def create
    return render :new if params['user'].blank?

    @sign_in_form = SignInForm.new(params['user'])
    if session[:challenge_parameters].present? || @sign_in_form.valid?
      super
    else
      render :new
    end
  end

  def destroy
    UserSignOutEvent.create(user_id: warden.user.user_id)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out
    yield if block_given?
    respond_to_on_destroy
  end

  def cancel
    reset_session
    redirect_to new_user_session_path
  end

  def challenge_flash_messages
    return if session.to_h.dig('challenge_parameters', 'flash_message').nil?

    msg = session.to_h.dig('challenge_parameters', 'flash_message', 'code')
    session[:challenge_parameters].delete('flash_message')
    set_flash_message! :warn, msg.to_sym, now: true
  end

  def load_secret_code
    @secret_code = session[:secret_code]
    @secret_code_svg = generate_new_qr(secret_code: session[:secret_code], email: session[:email]) unless session[:secret_code].nil?
  end
end
