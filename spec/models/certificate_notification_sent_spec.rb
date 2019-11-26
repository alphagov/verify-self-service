require 'rails_helper'

RSpec.describe CertificateNotificationSentEvent, type: :model do
  it 'is valid and persisted with notification_sent updated to true' do
    certificate = create(:sp_signing_certificate)
    expect(certificate.notification_sent).to eql(false)
    certificate_notification_sent_event = create(:certificate_notification_sent_event, certificate: certificate)
    expect(certificate_notification_sent_event).to be_valid
    expect(certificate_notification_sent_event).to be_persisted
    expect(certificate.notification_sent).to eql(true)
  end
end
