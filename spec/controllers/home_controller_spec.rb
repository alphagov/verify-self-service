require 'rails_helper'

RSpec.describe HomeController, type: :controller do

  before(:each) do
    get_auth_hash
  end

  describe "GET #index" do
    it "returns http success" do
      session[:userinfo] = "Test User"
      get :index
      expect(response).to have_http_status(:success)
    end
  end
end