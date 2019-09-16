  require 'rails_helper'

RSpec.describe MsaComponentsController, type: :controller do
  include AuthSupport

  let(:msa_component) { create(:msa_component) }

  describe "GET #index" do
    it "returns http success" do
      compmgr_stub_auth
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #new" do
    it "returns http redirect for unauthorised user" do
      usermgr_stub_auth
      get :new
      expect(flash[:warn]).to match(t('shared.errors.authorisation'))
      expect(response).to have_http_status(:forbidden)
    end

    it "returns http success with component manager user" do
      compmgr_stub_auth
      get :new
      expect(response).to have_http_status(:success)
    end
  end
end
