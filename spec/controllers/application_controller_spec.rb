require 'rails_helper'
require 'auth_test_helper'
RSpec.describe ApplicationController, type: :controller do
  
  it "Login URL points to developer provider" do
    expect(subject.login_url).to eq("/auth/developer")
  end

  it "authenticate_user! with session sets @current_user" do
      populate_session
      subject.authenticate_user!
      expect(subject.current_user).to eq("Test User")
  end
end
