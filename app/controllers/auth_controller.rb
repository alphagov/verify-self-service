class AuthController < ApplicationController
  # Required for OmniAuth Dev Flow... Not to be used in Production
  skip_before_action :verify_authenticity_token, only: :callback unless Rails.env.production?
  skip_before_action :authenticate_user!
  
  def create
    auth_hash = request.env['omniauth.auth']
    
    if session[:user_id]
      # Means our user is signed in. Add the authorization to the user
      User.find(session[:user_id]).add_provider(auth_hash)
 
      render :text => "You can now login using #{auth_hash["provider"].capitalize} too!"
    else
      # Log him in or sign him up
      auth = Authorization.find_or_create(auth_hash)
 
      # Create the session
      session[:user_id] = auth.user.id
   
      render :text => "Welcome #{auth.user.name}!"
    end
    redirect_to session[:redirect_path] || root_path
  end

  # This stores all the user information that came from the Auth Provider
  # and the IdP
  def callback
    auth_hash = request.env['omniauth.auth']
    session[:provider] = auth_hash[:provider]
    session[:userinfo] = auth_hash[:extra]["raw_info"]
    # Redirect to the URL you want after successful auth
    redirect_to session[:redirect_path] || root_path
  end

  # This handles authentication failures
  def failure
    @error_type = request.params['error_type']
    @error_msg = request.params['error_msg']
  end

  def logout
    redirect_to logout_url
  end

  def destroy
    session[:userinfo] = nil
    redirect_to login_url
  end
end
