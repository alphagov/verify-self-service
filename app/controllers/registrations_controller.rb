class RegistrationsController < Devise::RegistrationsController
  before_action :configure_account_update_params, only: [:update]
  prepend_before_action :authenticate_scope!, only: %i[edit update destroy create new]

  def edit
    render :edit
  end

  def update
    self.resource = send(:"authenticate_#{resource_name}!", force: true)
    resource_updated = update_resource(resource, account_update_params)
    yield resource if block_given?
    if resource_updated
      set_flash_message_for_update(resource, "prev_unconfirmed_email")
      bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?

      respond_with resource, location: after_update_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  def update_resource(resource, params)
    if params.has_key?(:session_only) && params[:session_only]
      resource.update_without_password(params)
    else
      resource.update_with_password(params)
    end
  end

protected

  def authenticate_scope!
    self.resource = send(:"authenticate_#{resource_name}!", force: true)
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: %i[user_id phone_number given_name family_name roles session_only])
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    super(resource)
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    super(resource)
  end
end
