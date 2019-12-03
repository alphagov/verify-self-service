require 'rails_helper'

RSpec.describe 'Healthcheck Page', type: :system do
  it 'displays healthcheck' do
    stub_request(:get, "http://config-service.test/service-status")
      .to_return(status: 200, body: "", headers: {})
    visit healthcheck_path
    expect(page).to have_content '{"status":"ok","checks":{"cognito_connectivity":{"status":"ok"},"database_connectivity":{"status":"ok"},"storage_connectivity":{"status":"ok"},"hub_connectivity":{"status":"ok"}}}'
  end
end