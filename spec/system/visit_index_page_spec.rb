require 'rails_helper'

RSpec.describe 'IndexPage', type: :system do
  let(:msa_signing_certificate) { create(:msa_signing_certificate) }
  let(:msa_encryption_certificate) { create(:msa_encryption_certificate) }
  let(:sp_encryption_certificate) { create(:sp_encryption_certificate) }

  before(:each) do
    login_gds_user
    ReplaceEncryptionCertificateEvent.create(
      component: sp_encryption_certificate.component,
      encryption_certificate_id: sp_encryption_certificate.id
    )
    ReplaceEncryptionCertificateEvent.create(
      component: msa_encryption_certificate.component,
      encryption_certificate_id: msa_encryption_certificate.id
    )
  end

  it 'shows greeting without JS' do
    visit '/'
    expect(page).to have_content 'Manage certificates'
  end

  it 'shows greeting with JS', js: true do
    visit '/'
    expect(page).to have_content 'Manage certificates'
  end

  it 'shows index page and successfully goes to next page' do   
    msa_component = msa_encryption_certificate.component
    visit root_path
    expect(page).to have_content 'Manage certificates'
    click_link('Encryption certificate', match: :first)
    expect(current_path).to eql view_certificate_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
  end

  it 'shows whether signing certificate is primary or secondary when there are two signing certificates' do
    second_signing_certificate = create(:msa_signing_certificate, component: msa_signing_certificate.component)
    visit root_path
    table_row_content_primary = page.find("##{second_signing_certificate.id}")
    table_row_content_secondary = page.find("##{msa_signing_certificate.id}")
    expect(table_row_content_primary).to have_content 'Signing certificate (primary)'
    expect(table_row_content_secondary).to have_content 'Signing certificate (secondary)'
    expect(table_row_content_secondary).to have_content 'IN USE'
  end

  it 'shows when a second signing certificate is added the new certificate becomes primary and the older one becomes secondary' do
    visit root_path
    expect(page).to_not have_content 'Signing certificate (primary)'
    expect(page).to_not have_content 'Signing certificate (secondary)'
    second_signing_certificate = create(:msa_signing_certificate, component: msa_signing_certificate.component)
    visit root_path
    primary_certificate_link = find_link('Signing certificate (primary)')['href']
    secondary_certificate_link = find_link('Signing certificate (secondary)')['href']
    expect(primary_certificate_link).to have_content second_signing_certificate.id
    expect(secondary_certificate_link).to have_content msa_signing_certificate.id
  end

  it 'shows certificate expiry tag and expiry message if certificate expires under 30 days' do
    expiring_certificate = create(:msa_signing_certificate, value: PKI.new.generate_encoded_cert(expires_in: 29.days))
    visit root_path
    table_row_content = page.find("##{expiring_certificate.id}")
    expect(table_row_content).to have_content 'EXPIRES IN 29 DAYS'
  end

  it 'shows in use tag if certificate is ok' do
    cert_id = msa_signing_certificate.id
    visit root_path 
    table_row_content = page.find("##{cert_id}")
    expect(table_row_content).to have_content 'IN USE'
  end

  it 'shows deploying tag if a second signing certificate has been uploaded' do
    second_signing_certificate = create(:msa_signing_certificate, component: msa_signing_certificate.component)
    visit root_path
    table_row_content = page.find("##{second_signing_certificate.id}")
    expect(table_row_content).to have_content 'DEPLOYING'
  end

  it 'shows missing tag if encyrption certificate value has not been uploaded' do
    sp_component = create(:sp_component)
    visit root_path
    expect(page).to have_content 'Encryption certificate'
    expect(page).to have_content 'MISSING'
  end

  it 'shows the number of expiriing certificates at the top of the page' do
    first_expiring_certificate = create(:msa_signing_certificate, value: PKI.new.generate_encoded_cert(expires_in: 29.days))
    second_expiring_certificate = create(:msa_signing_certificate, value: PKI.new.generate_encoded_cert(expires_in: 29.days))
    visit root_path
    expect(page).to have_content '2 certificates are expiring soon.'
  end

end
