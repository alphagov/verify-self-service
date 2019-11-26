require 'notifications/client'

module Notification
  def client
    Notifications::Client.new(ENV.fetch('NOTIFY_KEY'))
  end

  def send_email(email_address:)
    client.send_email(
      email_address: email_address,
      template_id: "a0578c4a-3373-48c0-b041-c61fcdf4f843",
      personalisation: { team: "test" },
     )
  end
end
