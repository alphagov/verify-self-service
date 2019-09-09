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
end
