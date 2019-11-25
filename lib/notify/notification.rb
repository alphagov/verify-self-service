require 'notifications/client'

module Notification
  INVITE_TEMPLATE = "afdb4827-0f71-4588-b35d-80bd514f5bdb".freeze

  def mail_client
    Notifications::Client.new(ENV.fetch('NOTIFY_KEY'))
  end

  def send_invitation_email(opts)
    mail_client.send_email(
      email_address: opts[:email_address],
      template_id: INVITE_TEMPLATE,
      personalisation: { first_name: opts[:first_name], temporary_password: opts[:temporary_password] }
     )
  end
end
