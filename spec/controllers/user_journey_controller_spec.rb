require 'rails_helper'

RSpec.describe UserJourneyController, type: :controller do
  include AuthSupport
  include CertificateSupport

  describe "GET #index" do
    it "returns http success" do
      certmgr_stub_auth
      get :index
      expect(response).to have_http_status(:success)
    end

    it "should redirect to sign-page" do
      get :index
      expect(response).to have_http_status(:redirect)
      expect(subject).to redirect_to(new_user_session_path)
      expect(subject).not_to redirect_to(root_path)
    end
  
    it "should render when logged in" do
      certmgr_stub_auth
      get :index
      expect(response).to have_http_status(:success)
      expect(subject).not_to redirect_to(new_user_session_path)
      expect(subject).to render_template(:index)
    end
  end

  describe '#view_certificate' do
    it 'renders the view certificate page' do
      certmgr_stub_auth
      get :view_certificate, params: { component_type: 'MsaComponent', component_id: 1, certificate_id: 1 }
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:view_certificate)
    end
  end

  describe '#before_you_start' do
    it 'renders the before you start page' do
      certmgr_stub_auth
      get :before_you_start, params: { component_type: 'MsaComponent', component_id: 1, certificate_id: 1 }
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:before_you_start)
    end
  end

  describe '#upload_certificate' do
    it 'renders upload certificate page' do
      certmgr_stub_auth
      get(:upload_certificate, params: { component_type: 'MsaComponent', component_id: 1, certificate_id: 1 })
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:upload_certificate)
    end
  end

  describe '#check_your_certificate' do
    it 'renders check your certificate page' do
      certmgr_stub_auth
      certificate = create(:msa_encryption_certificate)
      msa_component = certificate.component
      post(:submit, params: { component_type: 'MsaComponent', component_id: 1, certificate_id: 1, certificate: { value: certificate.value } })
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:check_your_certificate)
    end
  end

  describe '#confirmation' do
    it 'renders confirmation page' do
      certmgr_stub_auth
      certificate = create(:msa_encryption_certificate)
      msa_component = certificate.component
      post(:confirm, params: { component_type: 'MsaComponent', component_id: 1, certificate_id: 1, certificate: { new_certificate: certificate.value } })
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:confirmation)
    end
  end
end
