require 'rails_helper'
require 'auth_test_helper'

RSpec.describe CertificatesController, type: :controller do
  before(:each) do
    populate_session
  end

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

end
