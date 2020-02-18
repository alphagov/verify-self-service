require 'notifications/client'
require 'auth/authentication_backend'
require 'notify/cert_status_notifications'
class CertificateInUseEvent < AggregatedEvent
  include AuthenticationBackend
  include CertStatusNotifications
  belongs_to_aggregate :certificate
  data_attributes :in_use_at
  after_create_commit :notify_service_team_members

  def attributes_to_apply
    { in_use_at: Time.now }
  end

  def notify_service_team_members
    recipients = team_recipients(certificate.component.team.team_alias)
    Rails.logger.error("No recipients found for #{certificate.component.team.name}!") if recipients.empty?
    mail_client = Notifications::Client.new(Rails.configuration.notify_key)

    recipients.each { |email|
      send_notification_email(mail_client: mail_client, certificate: certificate, email_address: email)
    }

    CertificateNotificationSentEvent.create(certificate: certificate)
  rescue Notifications::Client::RequestError => e
    Rails.logger.error(e.message)
  end
end
