require 'rails_helper'

RSpec.describe SpComponentsController, type: :controller do
  include AuthSupport

  let(:sp_component) { create(:sp_component) }

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
       get :edit, params: { id: sp_component.id }
       expect(response).to have_http_status(:success)
     end
   end

   describe "PATCH #update" do
     it "returns http success" do
       compmgr_stub_auth

       patch :update, params: { id: sp_component.id, component: { :name => 'test name', :type => COMPONENT_TYPE::SP, :environment => 'staging', :team_id => sp_component.team.id }}

       expect(subject).to redirect_to(sp_components_path)
     end

     it 'errors when invalid' do
       compmgr_stub_auth

       patch :update, params: { id: sp_component.id, component: { :name => '', :type => COMPONENT_TYPE::SP, :environment => 'staging', :team_id => sp_component.team.id }}

       expect(response).to have_http_status(:success)
       expect(response).to render_template("edit")
     end
   end
end
