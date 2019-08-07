require 'rails_helper'
RSpec.describe Admin::TeamsController, type: :controller do
  include AuthSupport
  
  before(:each) do
    stub_auth
  end
  
  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #new" do
    it "returns http success" do
      get :new
      expect(response).to have_http_status(:success)
    end
  end
end
