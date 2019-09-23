class GroupPolicy < ApplicationPolicy
  attr_reader :user, :object

  def initialize(user, object)
    @user = user
    @object = object
  end

  def team_authorized?
    check_membership(@user, @object.id)
  end

  alias_method :index?, :team_authorized?
  alias_method :show?, :team_authorized?
  alias_method :create?, :team_authorized?
  alias_method :update?, :team_authorized?
  alias_method :destroy?, :team_authorized?
  alias_method :invite?, :team_authorized?
  alias_method :before_you_start?, :team_authorized?
  alias_method :view_certificate?, :team_authorized?
  alias_method :upload_certificate?, :team_authorized?
  alias_method :upload?, :team_authorized?
  alias_method :check_your_certificate?, :team_authorized?
  alias_method :submit?, :team_authorized?
  alias_method :confirmation?, :team_authorized?
  alias_method :confirm?, :team_authorized?

private

  def check_membership(user, object_id)
    return true if user.roles.include?('gds')

    object_id == user&.team
  end
end
