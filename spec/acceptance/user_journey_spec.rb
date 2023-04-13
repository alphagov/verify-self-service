require 'rails_helper'
require 'acceptance_helper'

include System::SessionHelpers
include CertificateSupport

RSpec.describe 'User journey', type: :feature, acceptance: true do
  let(:root) { PKI.new }
  let(:cert) { root.generate_encoded_cert(expires_in: 2.months) }
  let(:email) { ENV['ACCEPTANCE_TEST_EMAIL'] }
  let(:password) { ENV['ACCEPTANCE_TEST_PASSWORD'] }
  let(:totp) { ROTP::TOTP.new(ENV['TOTP_SECRET_CODE']) }

#  it 'signs in, rotates MSA encryption certificate and signs out', js: true do
#    sign_in_with_mfa
#    rotate_msa_encryption_certificate
#    sign_out
#  end

  def sign_in_with_mfa
    visit ENV['TEST_DOMAIN']

    expect(page).to have_content t('sign_in.title')

    fill_in 'Email', with: email
    fill_in 'Password', with: password
    click_button t('sign_in.sign_in')

    expect(page).to have_content t('sign_in.mfa_heading')

    totp_sign_in(totp.now)

    expect(page).to have_content t('components.title')
  end

  def rotate_msa_encryption_certificate
    find('.govuk-table__row', text: "#{t('user_journey.encryption_certificate')}\n#{t('user_journey.in_use')}", match: :first).click_link

    expect(page).to have_content 'Matching Service Adapter: encryption certificate'

    # Text changes depending on state, hence using the css class
    find('.govuk-button').click

    expect(page).to have_content t('user_journey.before_you_start.title')

    click_link 'I have updated my MSA configuration'

    choose t('user_journey.certificate.paste_certificate'), visible: false
    fill_in 'certificate_value', with: cert, visible: false
    click_button t('user_journey.continue')

    expect(page).to have_content t('user_journey.certificate.check_certificate_title')

    click_button t('user_journey.certificate.use_certificate')

    expect(page).not_to have_content t('certificates.errors.cannot_publish')

    expect(page).to have_content t('user_journey.adding_certificate_to_config')

    visit ENV['TEST_DOMAIN']

    expect(page).to have_css ".govuk-table", text: t('user_journey.component_long_name.MSA')
    expect(page).to have_css ".govuk-table", text: t('user_journey.encryption_certificate')
    expect(page).to have_css ".govuk-table", text: "DEPLOYING"
  end

  def sign_out
    click_link t('layout.application.sign_out_link')

    expect(page).to have_content t('sign_in.title')
  end
end
