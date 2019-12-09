desc 'Email users if their certs are due to expire soon'
task 'send_cert_expiry_reminder_emails' => :environment do
  Rails.logger.info("Scheduled rake task started")
  CertificateExpiryReminder::Check.new().run
  Rails.logger.info("Scheduled rake task ended")
end
