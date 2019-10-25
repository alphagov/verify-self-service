require 'rails_helper'
RSpec.describe ServicesController, type: :controller do
  include AuthSupport

  let(:sp_component) { create(:sp_component) }
  let(:service) { create(:service, sp_component_id: sp_component) }

  before(:each) do
    compmgr_stub_auth
  end

  describe "GET #index" do
    it "returns http success" do
      get :index, params: { sp_component_id: sp_component }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'DELETED #destroy' do
    it 'expects DeleteServiceEvent to be called when deleting service' do
      expect(DeleteServiceEvent).to receive(:create).and_call_original
      delete :destroy, params: { id: service.id }
      expect(Service.exists?(service.id)).to be false
    end
    it 'displays service that was removed' do
      delete :destroy, params: { id: service.id }
      expect(flash[:success]).to eq t('common.action_successful', name: service.name, action: :deleted)
    end
  end
end

