require 'rails_helper'

RSpec.describe 'Healthcheck Page', type: :system do
  it 'displays healthcheck' do
    # TODO: Once we implement the proper HTTP client for talking to the hub, we should do proper stubbing
    visit healthcheck_path
    expect(page).to have_content '{"status":"service_unavailable","checks":{"cognito_connectivity":{"status":"ok"},"database_connectivity":{"status":"ok"},"storage_connectivity":{"status":"ok"},"hub_connectivity":{"status":"service_unavailable"}}}'
  end
end