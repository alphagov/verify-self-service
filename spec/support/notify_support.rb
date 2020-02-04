module NotifySupport
  NOTIFY_ENDPOINT = "https://api.notifications.service.gov.uk/v2/notifications/email".freeze

  def stub_notify_response
    stub_request(:post, NOTIFY_ENDPOINT)
      .to_return(status: 200, body: "{}", headers: {})
  end

  def stub_notify_request(body)
    a_request(:post, NOTIFY_ENDPOINT).with(body: body.to_json)
  end
end
