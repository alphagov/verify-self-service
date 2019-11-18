require 'rails_helper'
include AuthSupport
include CertificateSupport

RSpec.describe CertificatesController, type: :controller do
  let(:sp_component) { create(:sp_component) }
  let(:root) { PKI.new }
  let(:cert_value) { root.generate_encoded_cert(expires_in: 2.months) }
  let(:sp_signing_certificate) { create(:sp_signing_certificate) }

  describe 'GET #new' do
    it 'returns http success' do
      certmgr_stub_auth
      get :new, params: { sp_component_id: sp_component }

      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    it 'redirects after creating a certificate' do
      certmgr_stub_auth
      post :create, params: { certificate: { value: sp_signing_certificate.value, usage: CERTIFICATE_USAGE::SIGNING }, sp_component_id: sp_component }

      expect(subject).to redirect_to(sp_component_path(sp_component))
      expect(flash.now[:errors]).to be_nil
    end

    it 'renders new when invalid' do
      certmgr_stub_auth
      post :create, params: { certificate: { value: '', usage: CERTIFICATE_USAGE::SIGNING }, sp_component_id: sp_component }

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:new)
    end
  end

  describe 'PATCH #enable' do
    it 'redirects after enabling a certificate' do
      certmgr_stub_auth
      patch :enable, params: { id: sp_signing_certificate, sp_component_id: sp_component }

      expect(subject).to redirect_to(sp_component_path(sp_signing_certificate.component_id))
      expect(flash.now[:errors]).to be_nil
    end
 end

  describe 'PATCH #disable' do
    it 'redirects after disabling a certificate' do
      certmgr_stub_auth
      patch :disable, params: { id: sp_signing_certificate, sp_component_id: sp_component }

      expect(subject).to redirect_to(sp_component_path(sp_signing_certificate.component_id))
      expect(flash.now[:errors]).to be_nil
    end
  end

  describe 'PATCH #replace' do
    it 'redirects after replacing a certificate' do
      certmgr_stub_auth
      patch :replace, params: { certificate: sp_signing_certificate, component: sp_component, sp_component_id: sp_component, id: sp_signing_certificate }

      expect(subject).to redirect_to(sp_component_path(sp_component))
      expect(flash.now[:errors]).to be_nil
    end
  end
end
