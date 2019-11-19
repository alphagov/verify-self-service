class UpdateUserNameForm
  include ActiveModel::Model

  attr_reader :family_name, :given_name
  validates_presence_of :family_name, :given_name

  def initialize(params = {})
    @family_name = params[:family_name]
    @given_name = params[:given_name]
  end
end
