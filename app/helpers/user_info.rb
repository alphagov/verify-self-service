module UserInfo
  def current_user
    RequestStore.store[:user]
  end

  def self.current_user=(user)
    RequestStore.store[:user] = user
  end
end
