require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
#   it "authenticate_user! without session redirects to login path" do
    
#     allow(controller).to receive(:redirect_to)
#     subject.authenticate_user!
#     #expect(response[:Location]).to eq(subject.login_path)
#     # subject.authenticate_user!
#     expect(subject).to redirect_to '/auth/cognito-idp/'
#   end

  it "Login URL points to cognito-idp" do
    expect(subject.login_url).to eq('/auth/cognito-idp/')
  end

  it "authenticate_user! with session sets @current_user" do
      session[:userinfo] = "Test User"
      subject.authenticate_user!
      expect(subject.current_user).to eq("Test User")
  end
end