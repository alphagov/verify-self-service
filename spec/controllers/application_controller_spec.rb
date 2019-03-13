require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do

  it "Login URL points to cognito-idp" do
    expect(subject.login_url).to eq("/auth/cognito-idp/")
  end

  it "authenticate_user! with session sets @current_user" do
      session[:userinfo] = "Test User"
      subject.authenticate_user!
      expect(subject.current_user).to eq("Test User")
  end
end