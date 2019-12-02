require 'notifications/client'

module Notification
  INVITE_TEMPLATE = "afdb4827-0f71-4588-b35d-80bd514f5bdb".freeze

  def mail_client
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

  def url
    if Rails.env.production?
      "https://#{Rails.configuration.app_url}"
    else
      "http://#{Rails.configuration.app_url}"
    end
  end
end
