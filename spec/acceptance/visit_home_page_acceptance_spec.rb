require 'acceptance_helper'

RSpec.describe 'Homepage', type: :feature, acceptance: true do
  it 'shows greeting with JS', js: true do
    visit "https://#{ENV['TEST_DOMAIN']}"
    fill_in('user_email', with: 'test@test.test')
    fill_in('user_password', with: 'Password!1')
    find("[name='commit']").click
    expect(page).to have_content 'Components'
  end
end
