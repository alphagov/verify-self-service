# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [
  :access_token,
  :code,
  :email,
  :family_name,
  :full_name,
  :given_name,
  :new_password,
  :password,
  :phone_number,
  :temporary_password,
  :totp_code
]
