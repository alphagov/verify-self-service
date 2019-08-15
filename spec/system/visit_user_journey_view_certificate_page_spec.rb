require 'rails_helper'

RSpec.describe 'View certificate page', type: :system do
  include CertificateSupport

  before(:each) do
    login_certificate_manager_user
  end
  
  let(:msa_component) { create(:msa_component, encryption_certificate_id: 1) }
  let(:sp_component) { create(:sp_component, encryption_certificate_id: 1) }
  let(:root) { PKI.new }
  let(:x509_cert) { root.generate_encoded_cert(expires_in: 9.months) }

  it 'shows existing msa encryption certificate information and successfully goes to next page' do
    defaults = {
      usage: CERTIFICATE_USAGE::ENCRYPTION,
      value: x509_cert,
      component: msa_component
    }
    Certificate.create(defaults)
    visit view_certificate_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
    expect(page).to have_content 'Matching Service Adapter: encryption certificate'
    click_link 'Replace certificate'
    expect(current_path).to eql before_you_start_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
  end

  it 'shows existing vsp encryption certificate information and successfully goes to next page' do
    defaults = {
      usage: CERTIFICATE_USAGE::ENCRYPTION,
      value: x509_cert,
      component: sp_component
    }
    Certificate.create(defaults)
    visit view_certificate_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
    expect(page).to have_content 'Verify Service Provider: encryption certificate'
    click_link 'Replace certificate'
    expect(current_path).to eql before_you_start_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
  end
end
