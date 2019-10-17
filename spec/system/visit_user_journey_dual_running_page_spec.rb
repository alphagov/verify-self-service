require 'rails_helper'

RSpec.describe 'Before you start page', type: :system do
  include CertificateSupport

  let(:user) { login_certificate_manager_user }
  let(:sp_encryption_certificate) { create(:sp_encryption_certificate, component: create(:sp_component, team_id: user.team)) }

  before(:each) do
    login_certificate_manager_user
    ReplaceEncryptionCertificateEvent.create(
      component: sp_encryption_certificate.component,
      encryption_certificate_id: sp_encryption_certificate.id
    )
  end

  context 'shows dual running page for sp encryption journey' do
    it 'and if user selects no it goes to the next page with the optional route parameter' do
      sp_component = sp_encryption_certificate.component
      visit dual_running_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
      expect(page).to have_content 'Does your service provider support dual running?'
      find('label', text: 'No').click
      click_button 'Continue'
      expect(current_path).to eql before_you_start_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id, true)
    end

    it 'and if user selects yes it goes to the next page without the optional route parameter' do
      sp_component = sp_encryption_certificate.component
      visit dual_running_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
      expect(page).to have_content 'Does your service provider support dual running?'
      find('label', text: 'Yes').click
      click_button 'Continue'
      expect(current_path).to eql before_you_start_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
    end
  end
end