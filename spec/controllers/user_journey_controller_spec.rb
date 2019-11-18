require 'rails_helper'

RSpec.describe UserJourneyController, type: :controller do
  include AuthSupport
  include CertificateSupport
  include TempFileHelpers

  let(:team) { create(:team) }
  let(:msa_component) { create(:msa_component, team_id: team.id) }
  let(:msa_encryption_cert) { create(:msa_encryption_certificate) }
  let(:params) do
    {
      component_type: msa_component.component_type,
      component_id: msa_component.id,
      certificate_id: msa_encryption_cert.id
    }
  end

  before do
    ReplaceEncryptionCertificateEvent.create(
      component: msa_encryption_cert.component, encryption_certificate_id: msa_encryption_cert.id
    )
  end

  context 'GET #index' do
    it 'should redirect to sign-page when not logged in' do
      get :index
      expect(response).to have_http_status(:redirect)
      expect(subject).to redirect_to(new_user_session_path)
      expect(subject).not_to redirect_to(root_path)
    end

    it 'returns http success' do
      certmgr_stub_auth
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'should render when logged in' do
      certmgr_stub_auth
      get :index
      expect(response).to have_http_status(:success)
      expect(subject).not_to redirect_to(new_user_session_path)
      expect(subject).to render_template(:index)
    end

    it 'should show the user their team components' do
      certmgr_stub_auth
      sp_component = create(:sp_component, team_id: @user.team)
      get :index
      expect(response).to have_http_status(:success)
      expect(@controller.instance_variable_get(:@components).length).to eq(1)
      expect(@controller.instance_variable_get(:@components)[0].team_id).to eq(sp_component.team_id)
    end

    it 'should not show user components with different id' do
      certmgr_stub_auth
      create(:sp_component)
      get :index
      expect(response).to have_http_status(:success)
      expect(@controller.instance_variable_get(:@components).length).to eq(0)
      expect(@controller.instance_variable_get(:@components)[0]).to eq(nil)
    end

    it 'should only show the user their team components with the same id' do
      certmgr_stub_auth
      sp_component = create(:sp_component, team_id: @user.team)
      create(:sp_component)
      get :index
      expect(response).to have_http_status(:success)
      expect(@controller.instance_variable_get(:@components).length).to eq(1)
      expect(@controller.instance_variable_get(:@components)[0].team_id).to eq(sp_component.team_id)
    end
  end

  context '#view_certificate ' do
    it 'renders the view certificate page' do
      certmgr_stub_auth(team)
      get :view_certificate, params: params
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:view_certificate)
    end

    it 'returns http redirect for unauthorised user' do
      usermgr_stub_auth
      get :view_certificate, params: params
      expect(flash[:warn]).to match(t('shared.errors.authorisation'))
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'PATCH #disable_certificate' do
    it 'should disable the cert and redirect to homepage' do
      signing_cert_primary = create(:msa_signing_certificate, component: msa_component)
      signing_cert_secondary = create(:msa_signing_certificate, component: msa_component)
      certmgr_stub_auth(team)
      patch :disable_certificate, params: {
        component_type: msa_component.component_type,
        component_id: msa_component.id,
        certificate_id: signing_cert_secondary.id
      }
      expect(response).to have_http_status(:redirect)
      expect(subject).to redirect_to(root_path)
    end

    it 'should display error message if cannot disable cert' do
      signing_cert_only_one = create(:msa_signing_certificate, component: msa_component)
      certmgr_stub_auth(team)
      patch :disable_certificate, params: {
        component_type: msa_component.component_type,
        component_id: msa_component.id,
        certificate_id: signing_cert_only_one.id
      }
      expect(subject).to render_template(:view_certificate)
      expect(subject).not_to redirect_to(root_path)
      expect(flash[:error][0]).to include(t('certificates.errors.cannot_disable'))
    end
  end

  context '#dual_running ' do
    it 'renders the dual running page' do
      certmgr_stub_auth(team)
      get :dual_running, params: params
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:dual_running)
    end

    it 'should show the next page with the dual running option' do
      certmgr_stub_auth(team)
      get :is_dual_running,
        params: params.merge({
          dual_running: 'no'
        })
      expect(response).to redirect_to before_you_start_path(dual_running: true)
    end

    it 'should show the next page without the dual running option' do
      certmgr_stub_auth(team)
      get :is_dual_running,
        params: params.merge({
          dual_running: ''
        })
      expect(response).to redirect_to before_you_start_path
    end

    it 'should show error message when an option has not been selected' do
      certmgr_stub_auth(team)
      get :is_dual_running, params: params
      expect(response).to redirect_to :dual_running
      expect(flash[:error]).to include(I18n.t('user_journey.errors.select_option'))
    end
  end

  context '#before_you_start' do
    it 'renders the before you start page' do
      certmgr_stub_auth(team)
      get :before_you_start, params: params
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:before_you_start)
    end
  end

  context '#upload_certificate ' do
    it 'renders upload certificate page' do
      certmgr_stub_auth(team)
      get :upload_certificate, params: params
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:upload_certificate)
    end
  end

  context '#check_your_certificate' do
    it 'renders upload certificate page when cert pasted' do
      certmgr_stub_auth(team)
      post :submit,
           params: params.merge({
             'upload-certificate': 'string',
             certificate: { value: msa_encryption_cert.value, component: msa_component }
           })
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:check_your_certificate)
    end

    it 'renders upload certificate page when cert file uploaded' do
      certmgr_stub_auth(team)
      post :submit,
           params: params.merge({
             'upload-certificate': 'file',
             certificate: {
               cert_file: upload_file(
                 name: 'valid.pem',
                 type: CertificateExtractor::MIME_PEM,
                 content: PKI.new.generate_signed_cert.to_pem
               ),
               component: msa_component
             }
           })

      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:check_your_certificate)
    end
  end

  describe '#confirmation' do
    it 'renders confirmation page' do
      certmgr_stub_auth(team)
      certificate = create(:msa_encryption_certificate)
      msa_component = certificate.component
      post :confirm,
           params: params.merge({
             'upload-certificate': 'string',
             certificate: { new_certificate: certificate.value }
           })
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:confirmation)
    end
  end

  context 'submit with invalid certificate' do
    it 'should redirect to upload certificate page when certificate is invalid' do
      certmgr_stub_auth(team)
      post :submit,
           params: params.merge({
             'upload-certificate': 'string',
             certificate: {
               value: create(
                 :msa_encryption_certificate,
                 value: PKI.new.generate_encoded_cert(expires_in: 9000.months),
                 component: msa_component
               ).value
             }
           })

      expect(subject).to render_template(:upload_certificate)
      expect(
        assigns(:upload).errors.full_messages.first
      ).to include(I18n.t('certificates.errors.valid_too_long'))
    end

    it 'should redirect to upload certificate page when certificate file is invalid' do
      certmgr_stub_auth(team)
      post :submit,
           params: params.merge({
             'upload-certificate': 'file',
             certificate: {
               cert_file: upload_file(
                 name: 'invalid.txt',
                 type: 'text/rtf',
                 content: 'It was a bright, cold day in April and the clocks were striking thirteen'
               ),
               component: msa_component
             }
           })

      expect(subject).to render_template(:upload_certificate)
      expect(
        assigns(:upload).errors.full_messages.first
      ).to include(I18n.t('certificates.errors.invalid_file_type'))
    end

    it 'should redirect to upload certificate page with valid file extension but invalid content' do
      certmgr_stub_auth(team)
      post :submit,
           params: params.merge({
             'upload-certificate': 'file',
             certificate: {
               cert_file: upload_file(
                 name: 'invalid.crt',
                 type: CertificateExtractor::MIME_PEM,
                 content: 'Whats it going to be then, eh?'
               ),
              component: msa_component
             }
           })

      expect(subject).to render_template(:upload_certificate)
      expect(
        assigns(:upload).errors.full_messages.first
      ).to include(I18n.t('certificates.errors.invalid'))
    end
  end

  context 'should choose the method selected by the radio button' do
    it 'file radio button selected' do
      certmgr_stub_auth(team)
      post :submit,
           params: params.merge({
             'upload-certificate': 'file',
             certificate: {
               cert_file: upload_file(
                 name: 'valid.pem',
                 type: CertificateExtractor::MIME_PEM,
                 content: PKI.new.generate_signed_cert.to_pem
               ),
               value: 'Time is not a line but a dimension, like the dimensions of space',
               component: msa_component
             }
           })

      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:check_your_certificate)
    end

    it 'pasted cert radio button chosen' do
      certmgr_stub_auth(team)
      post :submit,
           params: params.merge({
             'upload-certificate': 'string',
             certificate: {
               cert_file: upload_file(
                 name: 'valid.pem',
                 type: CertificateExtractor::MIME_PEM,
                 content: 'It was a pleasure to burn'
               ),
               value: msa_encryption_cert.value,
               component: msa_component
             }
           })

      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:check_your_certificate)
    end

    it 'will attempt to extract only the selected radio button value' do
      certmgr_stub_auth(team)
      post :submit,
           params: params.merge({
             'upload-certificate': 'file',
             certificate: { value: msa_encryption_cert.value, component: msa_component }
           })

      expect(subject).to render_template(:upload_certificate)
      expect(
        assigns(:upload).errors.full_messages.first
      ).to include(I18n.t('certificates.errors.invalid_file_type'))
    end
  end

  context 'confirm with invalid certificate' do
    it 'should render upload certificate page when certificate is invalid' do
      certmgr_stub_auth(team)
      post :confirm,
           params: params.merge({
             'upload-certificate': 'string',
             certificate: { new_certificate: 'Snowman wakes before dawn', component: msa_component }
           })

      expect(subject).to render_template(:upload_certificate)
      expect(
        assigns(:upload).errors.full_messages.first
      ).to include(I18n.t('certificates.errors.invalid'))
    end
  end

  context 'Enforcement of component team restrictions' do
    it 'prevents rendering of the upload certificate page when team is not matching' do
      certmgr_stub_auth
      foreign_team = create(:team, id: SecureRandom.uuid)
      foreign_component = create(:sp_component, team_id: foreign_team.id)
      get :upload_certificate,
          params: {
            component_type: foreign_component.component_type,
            component_id: foreign_component.id,
            certificate_id: msa_encryption_cert.id
          }
      expect(response).to_not have_http_status(:success)
      expect(subject).to_not render_template(:upload_certificate)
      expect(response).to have_http_status(:forbidden)
      expect(flash[:warn]).to eq t('shared.errors.authorisation')
    end

    it 'behaves gracefully if a non-existent component is accessed' do
      certmgr_stub_auth
      get :upload_certificate,
          params: {
            component_type: :sp_component,
            component_id: 'bad id',
            certificate_id: msa_encryption_cert.id
          }
      expect(subject).to render_template(:upload_certificate)
    end
  end
end
