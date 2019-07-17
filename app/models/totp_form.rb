class TotpForm
  include ActiveModel::Model
  attr_accessor(
      :totp_code, :cognito_session_id, :challenge_parameters, :email
  )
end