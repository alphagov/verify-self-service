require 'notifications/client'
module Notification
  INVITE_TEMPLATE = "afdb4827-0f71-4588-b35d-80bd514f5bdb".freeze
  REMINDER_TEMPLATE = "bbc34127-7fca-4d78-a95b-703da58e15ce".freeze
  CHANGED_NAME_TEMPLATE = "c6880583-6f8e-4820-bb2e-98125e355f72".freeze
  CHANGED_MFA_TEMPLATE = "029b2f45-72f2-4386-8149-71bf57ba86d1".freeze
  CHANGED_PASSWORD_TEMPLATE = "16557e1a-767f-42d9-a8d6-7f35ca57f0dd".freeze
  ADMIN_RESET_USER_PASSWORD_TEMPLATE = "335cc196-0260-493a-9fc7-7440a7110e7e".freeze
  OUT_OF_HOURS_ROTATION_TEMPLATE = "0cab7f14-c616-4541-8a73-55bf26b93479".freeze

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
    Rails.logger.error(e.message)
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
    Rails.logger.error(e.message)
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
    Rails.logger.error(e.message)
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
    Rails.logger.error(e.message)
  end

  def send_changed_password_email(email_address:, first_name:)
    mail_client.send_email(
      email_address: email_address,
      template_id: CHANGED_PASSWORD_TEMPLATE,
      personalisation: {
        first_name: first_name,
      },
     )
  rescue Notifications::Client::RequestError => e
    Rails.logger.error(e.message)
  end

  def send_admin_changed_user_password_email(email_address:, first_name:, reset_url:)
    mail_client.send_email(
      email_address: email_address,
      template_id: ADMIN_RESET_USER_PASSWORD_TEMPLATE,
      personalisation: {
        first_name: first_name,
        reset_url: "[#{url}#{reset_password_path}](#{url}#{reset_url})",
      },
     )
  rescue Notifications::Client::RequestError => e
    Rails.logger.error(e.message)
  end

  def send_out_of_hours_rotation_email(event_type:, user:, team:)
    mail_client.send_email(
      email_address: 'idasupport@digital.cabinet-office.gov.uk',
      template_id: OUT_OF_HOURS_ROTATION_TEMPLATE,
      personalisation: {
        event_type: event_type,
        user_name: user.full_name,
        user_email: user.email,
        user_team: team.name,
      },
     )
  rescue Notifications::Client::RequestError => e
    Rails.logger.error(e.message)
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
