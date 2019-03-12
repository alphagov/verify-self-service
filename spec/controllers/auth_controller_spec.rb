require 'rails_helper'

RSpec.describe AuthController, type: :controller do

  describe "GET #callback" do
    it "returns http success" do
      session[:userinfo] = "Test User"
      get :callback
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET #failure" do
    it "returns http success" do
      get :failure
      expect(response).to have_http_status(:success)
    end
  end

end
