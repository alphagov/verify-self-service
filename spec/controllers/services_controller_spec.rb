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
    context 'when service is present' do
      it 'expects DeleteServiceEvent to be called when deleting service' do
        expect(DeleteServiceEvent).to receive(:create).and_call_original
        delete :destroy, params: { id: service.id }
        expect(Service.exists?(service.id)).to be false
      end
      it 'expects flash to display service was deleted successfully' do
        delete :destroy, params: { id: service.id }
        expect(flash[:success]).to eq t('common.action_successful', name: service.name, action: :deleted)
      end
    end
    context 'when service is not present' do
      it 'expects flash to display service was not found' do
        delete :destroy, params: { id: 'non-existant' }
        expect(flash[:error]).to eq t('common.error_not_found', name: Service.model_name.human)
      end
    end
  end
end

