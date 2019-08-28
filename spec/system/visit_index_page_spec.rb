require 'rails_helper'

RSpec.describe 'IndexPage', type: :system do
  before(:each) do
    login_gds_user
  end

  it 'shows greeting without JS' do
    visit '/'
    expect(page).to have_content 'Manage certificates'
  end

  it 'shows greeting with JS', js: true do
    visit '/'
    expect(page).to have_content 'Manage certificates'
  end

  it 'shows whether signing certificate is primary or secondary when there are two signing certificates' do
    first_certificate = create(:msa_signing_certificate)
    create(:msa_signing_certificate, component: first_certificate.component)
    visit root_path
    expect(page).to have_content 'Signing certificate (primary)'
    expect(page).to have_content 'Signing certificate (secondary)'
  end

  it 'shows when a second signing certificate is added the new certificate becomes primary and the older one becomes secondary' do
    first_certificate = create(:msa_signing_certificate)
    visit root_path
    expect(page).to_not have_content 'Signing certificate (primary)'
    expect(page).to_not have_content 'Signing certificate (secondary)'
    second_certificate = create(:msa_signing_certificate, component: first_certificate.component)
    visit root_path
    primary_certificate_link = find_link('Signing certificate (primary)')['href']
    secondary_certificate_link = find_link('Signing certificate (secondary)')['href']
    expect(primary_certificate_link).to have_content second_certificate.id
    expect(secondary_certificate_link).to have_content first_certificate.id
  end

  it 'shows index page and successfully goes to next page' do
    certificate = create(:msa_encryption_certificate)
    msa_component = certificate.component
    visit root_path
    expect(page).to have_content 'Manage certificates'
    click_link('Encryption certificate', match: :first)
    expect(current_path).to eql view_certificate_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
  end

  it 'shows certificate expiring if under 30 days and IN USE if over 30 days' do
    certificate = create(:msa_encryption_certificate)
    expiring_certificate = create(:msa_signing_certificate, value: PKI.new.generate_encoded_cert(expires_in: 20.days))
    visit root_path
    expect(page).to have_content 'EXPIRES IN 20 DAYS'
    expect(page).to have_content 'IN USE'
  end
end
