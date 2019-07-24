require 'rails_helper'
module AuthSupport
  
  def stub_auth
    @request.env["devise.mapping"] = Devise.mappings[:user]
    user = FactoryBot.create(:user)
    sign_in user
  end
end
