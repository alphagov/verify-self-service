require 'notifications/client'

module Notification
  INVITE_TEMPLATE = "afdb4827-0f71-4588-b35d-80bd514f5bdb".freeze
  REMINDER_TEMPLATE = "bbc34127-7fca-4d78-a95b-703da58e15ce".freeze
  CHANGED_NAME_TEMPLATE = "c6880583-6f8e-4820-bb2e-98125e355f72".freeze
  CHANGED_MFA_TEMPLATE = "029b2f45-72f2-4386-8149-71bf57ba86d1".freeze

  REMINDER_TEMPLATE_SUBJECT = "your GOV.UK Verify certificates will expire on %s".freeze

  def mail_client
    Notifications::Client.new(Rails.configuration.notify_key)
  end

  def send_invitation_email(email_address:, first_name:, temporary_password:)
    mail_client.send_email(
      email_address: email_address,
      template_id: INVITE_TEMPLATE,
      personalisation: {
        first_name: first_name,
        url: url,
        temporary_password: temporary_password,
      },
     )
  rescue Notifications::Client::RequestError => e
    Rails.logger.error(e.to_s)
  end

  def send_reminder_email(email_address:, team_name:, days_left:, certificates:)
    expiry_date = (Time.now + days_left.days).strftime("%d %B %Y")
    subject = days_left == 3 ? "Urgent: #{REMINDER_TEMPLATE_SUBJECT}" % expiry_date : (REMINDER_TEMPLATE_SUBJECT % expiry_date).sub(/^./, &:upcase)
    mail_client.send_email(
      email_address: email_address,
      template_id: REMINDER_TEMPLATE,
      personalisation: {
        subject: subject,
        team: team_name,
        no_of_certs: certificates.count,
        multiple: certificates.count > 1 ? 'yes' : 'no',
        expire_on: expiry_date,
        certificates: certificates,
        url: url,
      },
     )
  rescue Notifications::Client::RequestError => e
    Rails.logger.error(e.to_s)
  end

  def send_changed_name_email(email_address:, new_name:)
    mail_client.send_email(
      email_address: email_address,
      template_id: CHANGED_NAME_TEMPLATE,
      personalisation: {
        new_name: new_name,
      },
     )
  rescue Notifications::Client::RequestError => e
    Rails.logger.error(e.to_s)
  end

  def send_changed_mfa_email(email_address:, first_name:)
    mail_client.send_email(
      email_address: email_address,
      template_id: CHANGED_MFA_TEMPLATE,
      personalisation: {
        first_name: first_name,
      },
     )
  rescue Notifications::Client::RequestError => e
    Rails.logger.error(e.to_s)
  end

private

  def url
    if Rails.env.production?
      "https://#{Rails.configuration.app_url}"
    else
      "http://#{Rails.configuration.app_url}"
    end
  end
end
