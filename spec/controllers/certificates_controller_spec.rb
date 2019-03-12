require 'rails_helper'

RSpec.describe CertificatesController, type: :controller do

  describe "GET #index" do
    it "returns http success" do
      session[:userinfo] = "Test User"
      get :index
      expect(response).to have_http_status(:success)
    end
  end

end
