class UpdateUserNameForm
  include ActiveModel::Model

  attr_reader :first_name, :last_name

  validates_presence_of :first_name, :last_name

  def initialize(params = {})
    @first_name = params[:first_name]
    @last_name = params[:last_name]
  end
end
