require 'rails_helper'

RSpec.describe 'Certificate Show Page', type: :system do
  include CognitoSupport

  before(:each) do
    login_gds_user
  end

  let(:user) { login_gds_user }
  let(:msa_encryption_certificate) { create(:msa_encryption_certificate, component: create(:msa_component, team_id: user.team)) }
  let(:sp_encryption_certificate) { create(:sp_encryption_certificate, component: create(:sp_component, team_id: user.team)) }

  it 'displays the certificate show page for msa certificate' do
    visit msa_component_certificate_path(msa_encryption_certificate.component.id ,msa_encryption_certificate.id)
    expect(page).to have_content ("Certificate ID: #{msa_encryption_certificate.id} ")
    expect(page).to have_content ("Name #{msa_encryption_certificate.x509.subject.to_s} ")
    expect(page).to have_content ("Usage #{msa_encryption_certificate.usage} ")
  end

  it 'displays the certificate show page for sp certificate' do
    visit sp_component_certificate_path(sp_encryption_certificate.component.id ,sp_encryption_certificate.id)
    expect(page).to have_content ("Certificate ID: #{sp_encryption_certificate.id} ")
    expect(page).to have_content ("Name #{sp_encryption_certificate.x509.subject.to_s} ")
    expect(page).to have_content ("Usage #{sp_encryption_certificate.usage} ")
  end
end
