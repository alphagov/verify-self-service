class MfaEnrolmentForm
  include ActiveModel::Model

  attr_reader :totp_code

  validates_presence_of :totp_code

  def initialize(hash = {})
    @totp_code = hash[:totp_code]
  end
end
