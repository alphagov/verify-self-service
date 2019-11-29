require 'notifications/client'

module Notification
  INVITE_TEMPLATE = "afdb4827-0f71-4588-b35d-80bd514f5bdb".freeze

  def mail_client
    check_for_key
    Notifications::Client.new(Rails.configuration.notify_key)
  end

  def send_invitation_email(opts)
    mail_client.send_email(
      email_address: opts[:email_address],
      template_id: INVITE_TEMPLATE,
      personalisation: {
        first_name: opts[:first_name],
        url: url,
        temporary_password: opts[:temporary_password],
      },
     )
  end

private

  def check_for_key
    if Rails.configuration.notify_key.nil?
      Rails.logger.warn "Notify API key not configured"
      puts "Notify API key not configured"
    end
  end

  def url
    if Rails.env.production?
      "https://#{Rails.configuration.app_url}"
    else
      "http://#{Rails.configuration.app_url}"
    end
  end
end
