require 'rails_helper'
require 'acceptance_helper'

RSpec.describe 'Homepage', type: :feature, acceptance: true do
  it 'visits the service home page successfully', js: true do
    visit ENV['TEST_DOMAIN']

    expect(page).to have_content t('layout.application.service_name')
  end
end
