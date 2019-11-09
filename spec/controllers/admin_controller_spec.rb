require 'rails_helper'

RSpec.describe AdminController, type: :controller do
  include AuthSupport
  include StorageSupport

  context 'GET #index' do
    it 'should render when GDS user' do
      gdsuser_stub_auth
      get :index
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:index)
    end

    it 'should not render when user is certificate manager' do
      certmgr_stub_auth
      get :index
      expect(flash[:warn]).to eq t('shared.errors.authorisation')
      expect(subject).to_not render_template(:index)
    end

    it 'should not render when user is user manager' do
      usermgr_stub_auth
      get :index
      expect(flash[:warn]).to eq t('shared.errors.authorisation')
      expect(subject).to_not render_template(:index)
    end
  end

  context 'GET #publish_metadata' do
    it 'should publish metadata for a given environment' do
      gdsuser_stub_auth
      PublishServicesMetadataEvent.delete_all
      get :publish_metadata, params: { environment: 'staging'}
      expect(PublishServicesMetadataEvent.all.count).to eq 1
      expect(flash[:notice]).to be nil
    end

    it 'should display warning if publishing metadata fails' do
      stub_storage_client_service_error
      gdsuser_stub_auth
      PublishServicesMetadataEvent.delete_all
      get :publish_metadata, params: { environment: 'staging'}
      expect(PublishServicesMetadataEvent.all.count).to eq 0
      expect(flash[:notice]).to eq(t('certificates.errors.cannot_publish'))
    end
  end
end
