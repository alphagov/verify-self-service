require 'rails_helper'

RSpec.describe 'Healthcheck Page', type: :system do
  it 'displays healthcheck' do
    visit healthcheck_path
    expect(page).to have_content '{"status":"ok","checks":{"cognito_connectivity":{"status":"ok"},"database_connectivity":{"status":"ok"},"storage_connectivity":{"status":"ok"}}}'
  end
end