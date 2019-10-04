class SessionsControllerPolicy < ApplicationPolicy
  def new?
    true
  end

  def create?
    true
  end

  def destroy?
    true
  end

  def cancel?
    true
  end
end
