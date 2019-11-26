require 'rails_helper'
require 'notify/notification'

RSpec.describe 'Notification' do
  include Notification

  let(:template) { 'afdb4827-0f71-4588-b35d-80bd514f5bdb' }
  let(:user) { create(:certificate_manager_user) }
  let(:temporary_password) { SecureRandom.urlsafe_base64(12) }

  let(:mail) { send_invitation_email(
    email_address: user.email,
    first_name: user.first_name,
    temporary_password: temporary_password
   )
  }

  it 'uses the correct Notify template' do
    expect(mail.template["id"]).to eq(template)
  end

  it 'displays the subject' do
    expect(mail.content["subject"]).to eq("You have been invited to collaborate on the GOV.UK Verify Manage certificates service")
  end

  it 'includes personalised content' do
    expect(mail.content["body"]).to eq("Dear #{user.first_name}\r\n\r\nYou have been invited to collaborate on the GOV.UK Verify Manage certificates service.\r\n\r\nSign in at http://www.test.com using the following temporary password:\r\n\r\n#{temporary_password}\r\n\r\nYou will be asked to create a new password and set up multi-factor authentication using your preferred authentication app.\r\n\r\nPlease sign in within 24 hours, otherwise the temporary password will expire.\r\n\r\nIf you miss this deadline, contact your admin to ask for another temporary password.\r\n\r\nThanks\r\n\r\nThe GOV.UK Verify team\r\nhttps://www.verify.service.gov.uk/")
  end
end
