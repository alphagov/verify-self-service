require 'rails_helper'

RSpec.describe Devise::SessionsController, type: :controller do
  it "Get to signin page" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      get :new
      expect(response.status).to eq(200)
    end

    it "Get 302 on TOTP request" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      #binding.pry
      post :create, :params => { email: "test@test.com", password: "validpass" }
      expect(response.status).to eq(302)
    end
end