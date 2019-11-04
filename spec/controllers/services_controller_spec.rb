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
  describe "GET #edit" do
    it "returns http success" do
      get :edit, params: { id: service.id }
      expect(response).to have_http_status(:success)
    end
  end
  describe "GET #update" do
    let(:entity_id) { "http://#{SecureRandom.uuid}.com" }
    it 'expects ChangeServiceEvent to be called changing service details'  do
      expect(ChangeServiceEvent).to receive(:create).and_call_original
      patch :update, params: {
        id: service.id,
        service: { name: SecureRandom.alphanumeric, entity_id: entity_id }
      }
      expect(subject).to redirect_to admin_path(anchor: :services)
      changed_service = ChangeServiceEvent.last.service
      expect(changed_service.entity_id).to eq entity_id
    end
    it 'errors when supplied with invalid input' do
      patch :update, params: {
        id: service.id, service: { name: '', entity_id: entity_id}
      }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
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

