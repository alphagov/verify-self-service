require 'rails_helper'

RSpec.describe 'IndexPage', type: :system do
  before(:each) do
    login_gds_user
  end

  let(:second_certificate) { PKI.new.generate_encoded_cert(expires_in: 9.months) }

  it 'shows greeting without JS' do
    visit '/'
    expect(page).to have_content 'Manage certificates'
  end

  it 'shows greeting with JS', js: true do
    visit '/'
    expect(page).to have_content 'Manage certificates'
  end

  it 'shows whether certificate is primary or secondary when there are two signing certificates' do
    first_certificate = create(:msa_signing_certificate)
    defaults = {
      usage: CERTIFICATE_USAGE::SIGNING,
      value: second_certificate,
      component: first_certificate.component
    }
    Certificate.create(defaults)
    visit root_path
    expect(page).to have_content 'Signing certificate (primary)'
    expect(page).to have_content 'Signing certificate (secondary)'
  end

end
