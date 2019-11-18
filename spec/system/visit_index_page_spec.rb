require 'rails_helper'

RSpec.describe 'IndexPage', type: :system do
  let(:msa_signing_certificate) { create(:msa_signing_certificate) }
  let(:msa_encryption_certificate) { create(:msa_encryption_certificate) }
  let(:sp_encryption_certificate) { create(:sp_encryption_certificate) }
  let(:sp_signing_certificate) { create(:sp_signing_certificate) }
  before(:each) do
    SpComponent.destroy_all
    MsaComponent.destroy_all
    login_gds_user
    create(:replace_encryption_certificate_event,
      component: sp_encryption_certificate.component,
      encryption_certificate_id: sp_encryption_certificate.id
    )
    create(:replace_encryption_certificate_event,
      component: msa_encryption_certificate.component,
      encryption_certificate_id: msa_encryption_certificate.id
    )
  end

  def get_row_status(node)
    node.respond_to?(:text) ? node.text.split("\n").last : node
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
    visit root_path
    expect(page).to have_content 'Manage certificates'
    within("##{msa_encryption_certificate.component_id}") do 
      click_link('Encryption certificate')
    end
    expect(current_path).to eql view_certificate_path(msa_encryption_certificate.id)
    expect(page).to have_title t('user_journey.certificate.title_current')
  end

  it 'displays which services a component is used by' do
    service = create(:service, sp_component: create(:sp_component), name: 'test-service')
    visit root_path
    component_table = page.find("##{service.sp_component.id}")
    expect(component_table).to have_content 'test-service'
  end

  it 'shows the primary signing certificate is deploying and secondary in use when deploying' do
    old_signing_certificate = create(:msa_signing_certificate, updated_at: 15.minutes.ago)
    new_signing_certificate = create(:msa_signing_certificate, component: old_signing_certificate.component)
    visit root_path
    table_row_content_primary = page.find("##{new_signing_certificate.id}")
    table_row_content_secondary = page.find("##{old_signing_certificate.id}")
    expect(table_row_content_primary).to have_content 'Signing certificate (primary)'
    expect(table_row_content_primary).to have_content 'DEPLOYING'
    expect(table_row_content_secondary).to have_content 'Signing certificate (secondary)'
    expect(table_row_content_secondary).to have_content 'IN USE'
  end

  it 'shows whether signing certificate is primary or secondary when there are two signing certificates' do
    second_signing_certificate = create(:msa_signing_certificate, component: msa_signing_certificate.component)
    travel_to Time.now + 11.minutes
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

  it 'shows certificate expiry tag if certificate expires under 30 days' do
    expiring_certificate = create(:msa_signing_certificate, value: PKI.new.generate_encoded_cert(expires_in: 29.days))
    visit root_path
    table_row_content = page.find("##{expiring_certificate.id}")
    expect(table_row_content).to have_content 'EXPIRES IN 29 DAYS'
  end

  it 'shows deploying tag if certificate is being deployed' do
    cert_id = msa_signing_certificate.id
    visit root_path
    table_row_content = page.find("##{cert_id}")
    expect(table_row_content).to have_content 'DEPLOYING'
  end

  it 'shows in use tag if certificate is ok after deployment' do
    cert_id = msa_signing_certificate.id
    travel_to Time.now + 11.minutes
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

  it 'shows missing tag if encryption certificate value has not been uploaded' do
    sp_component = create(:sp_component)
    visit root_path
    expect(page).to have_content 'Encryption certificate'
    expect(page).to have_content 'MISSING'
  end

  it 'shows the number of expiring certificates at the top of the page' do
    first_expiring_certificate = create(:msa_signing_certificate, value: PKI.new.generate_encoded_cert(expires_in: 29.days))
    second_expiring_certificate = create(:msa_signing_certificate, value: PKI.new.generate_encoded_cert(expires_in: 29.days))
    visit root_path
    expect(page).to have_content '2 certificates are expiring soon.'
  end

  it 'orders by environment and shows least expiring certificate first' do
    sp_production = create(:sp_component, environment: 'production')
    msa_integration = create(:msa_component, environment: 'integration')
    sp_integration = create(:sp_component, environment: 'integration')

    first_expiring_certificate = create(:sp_signing_certificate, value: PKI.new.generate_encoded_cert(expires_in: 19.days), component: sp_integration)
    second_expiring_certificate = create(:msa_signing_certificate, value: PKI.new.generate_encoded_cert(expires_in: 9.days), component: msa_integration)

    visit root_path
    first_expiring_certificate_row = page.find("##{first_expiring_certificate.id}")
    second_expiring_certificate_row = page.find("##{second_expiring_certificate.id}")

    expect(first_expiring_certificate_row).to have_content('EXPIRES IN 19 DAYS')
    expect(second_expiring_certificate_row).to have_content('EXPIRES IN 9 DAYS')
    expect(sp_production.environment.capitalize).to appear_before msa_integration.environment.capitalize
    expect(get_row_status(second_expiring_certificate_row)).to appear_before get_row_status(first_expiring_certificate_row)
  end
end
