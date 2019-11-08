  require 'rails_helper'

RSpec.describe MsaComponentsController, type: :controller do
  include AuthSupport

  let(:msa_component) { create(:msa_component) }
  let(:sp_component) { create(:sp_component) }
  let(:service) { create(:service) }

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

  describe "GET #edit" do
     it "returns http success" do
       compmgr_stub_auth
       get :edit, params: { id: msa_component.id }
       expect(response).to have_http_status(:success)
     end
   end

  describe "PATCH #update" do
    it "returns http success" do
      compmgr_stub_auth

      patch :update, params: { id: msa_component.id, component: { :name => 'test name', :entity_id => 'https://test.com', :environment => 'staging', :team_id => msa_component.team.id }}

      expect(subject).to redirect_to(msa_components_path)
    end

    it 'errors when invalid' do
      compmgr_stub_auth

      patch :update, params: { id: msa_component.id, component: { :name => '', :entity_id => 'https://test.com', :environment => 'staging', :team_id => msa_component.team.id }}

      expect(response).to have_http_status(:success)
      expect(response).to render_template("edit")
    end
  end

  describe "DELETE #destroy?" do
    it 'returns http redirect' do
      compmgr_stub_auth
      expect(MsaComponent.exists?(msa_component.id)).to be true
      delete :destroy, params: { id: msa_component.id }
      expect(MsaComponent.exists?(msa_component.id)).to be false
      expect(subject).to redirect_to(admin_path(anchor: 'MsaComponent'))
    end

    it 'returns http redirect with missing component' do
      compmgr_stub_auth
      MsaComponent.find_by_id(msa_component.id).delete
      expect(MsaComponent.exists?(msa_component.id)).to be false
      delete :destroy, params: { id: msa_component.id }
      expect(subject).to redirect_to(admin_path)
    end
  end

  describe "PATCH #associate_service" do
    it "returns http redirect" do
      compmgr_stub_auth

      patch :associate_service, params: { msa_component_id: msa_component.id, service_id: service.id }

      expect(subject).to redirect_to(msa_component_path(msa_component.id))
    end

    it "returns to admin page and flashes error when invalid" do
      compmgr_stub_auth

      patch :associate_service, params: { msa_component_id: sp_component.id, service_id: service.id }

      expect(flash[:error]).to eq(t('service.errors.unknown_component_or_service'))
      expect(subject).to redirect_to(admin_path(anchor: 'MsaComponent'))
    end
  end
end
