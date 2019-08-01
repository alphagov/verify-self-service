module UserInfo
  def current_user
    Thread.current[:user]
  end

  def self.current_user=(user)
    Thread.current[:user] = user
  end

  def self.all_users
    all_userpool_users = SelfService.service(:cognito_client).list_users(
      user_pool_id: Rails.application.secrets.cognito_user_pool_id
    ).users
    all_users = {}
    all_userpool_users.each do |user|
      attribs = self.user_attributes(user)
      all_users[attribs["sub"]] = attribs["given_name"] + " " + attribs["family_name"]
    end
    all_users
  end

  def self.user_attributes(user)
    user.attributes.map { |attribute|
      [attribute.name, attribute.value]
    }.to_h
  end
end
