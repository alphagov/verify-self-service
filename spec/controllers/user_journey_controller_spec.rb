require 'rails_helper'

RSpec.describe UserJourneyController, type: :controller do
  include AuthSupport
  include CertificateSupport

  let(:msa_component) { create(:msa_component, encryption_certificate_id: 1) }
  let(:root) { PKI.new }
  let(:x509_cert) { root.generate_encoded_cert(expires_in: 9.months) }

  describe "GET #index" do
    it "returns http success" do
      certmgr_stub_auth
      get :index
      expect(response).to have_http_status(:success)
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
    it 'renders upload certificate page' do
      certmgr_stub_auth
      defaults = {
        usage: CERTIFICATE_USAGE::ENCRYPTION,
        value: x509_cert,
        component: msa_component
      }
      Certificate.create(defaults)
      post(:submit, params: { component_type: 'MsaComponent', component_id: 1, certificate_id: 1, certificate: { value: x509_cert } })
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:check_your_certificate)
    end
  end
end
