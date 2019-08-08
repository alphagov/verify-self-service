class MfaEnrolmentForm
  include ActiveModel::Model

  attr_reader :code

  validates_presence_of :code

  def initialize(hash)
    @code = hash[:code]
  end
end
