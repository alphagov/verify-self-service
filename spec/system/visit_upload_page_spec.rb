require 'rails_helper'

RSpec.describe 'UploadPage', type: :system do
  include CertificateSupport

  before(:each) do
    login_certificate_manager_user
  end

  let(:component) { create(:msa_component) }
  let(:root) { PKI.new }
  let(:test_certificate) { root.generate_encoded_cert(expires_in: 2.months) }

  context 'Upload successful' do
    it 'submits a certificate' do
      visit new_msa_component_certificate_path(component)
      choose 'certificate_usage_signing', allow_label_click: true
      fill_in 'certificate_value', with: test_certificate
      click_button 'Upload'
      expect(page).to have_selector "#edit_certificate_#{component.certificates.last.id}"
      expect(current_path).to eql msa_component_path(component)
    end
  end
  context 'Upload fails' do
    context 'on MSA component' do
      it 'error summary links to form fields' do
        visit new_msa_component_certificate_path(component)
        click_button 'Upload'
        value_blank = find_link("Value can't be blank")
        not_a_valid_x509 = find_link('Certificate is not a valid x509 certificate')
        usage_not_included = find_link('Usage is not included in the list')
        within 'form#new_certificate' do
          expect(value_blank[:href]).to eq("##{t('certificates.new.msa_cert.value')}")
          expect(not_a_valid_x509[:href]).to eq("##{t('certificates.new.msa_cert.value')}")
          expect(usage_not_included[:href]).to eq("##{t('certificates.new.msa_cert.usage')}")
        end
      end
    end
    context 'on SP component' do
      it 'error summary links to form fields' do
        visit new_sp_component_certificate_path(create(:sp_component))
        click_button 'Upload'
        value_blank = find_link("Value can't be blank")
        not_a_valid_x509 = find_link('Certificate is not a valid x509 certificate')
        usage_not_included = find_link('Usage is not included in the list')
        within 'form#new_certificate' do
          expect(value_blank[:href]).to eq("##{t('certificates.new.msa_cert.value')}")
          expect(not_a_valid_x509[:href]).to eq("##{t('certificates.new.msa_cert.value')}")
          expect(usage_not_included[:href]).to eq("##{t('certificates.new.msa_cert.usage')}")
        end
      end
    end
  end
end
