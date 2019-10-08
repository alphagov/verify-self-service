class UpdateEmailVerificationCodeForm
  include ActiveModel::Model

  attr_reader :code
  validates_presence_of :code

  def initialize(options = {})
    @code = options[:code]
  end
end
