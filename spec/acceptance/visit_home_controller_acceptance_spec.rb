require 'acceptance_helper'

RSpec.describe 'Homepage', type: :feature, acceptance: true do

  it 'shows greeting with JS', js: true do
    visit "https://#{ENV["TEST_DOMAIN"]}/home/index"
    fill_in('username', :with => 'test@test.test')
    fill_in('password', :with => 'Password!1')
    find("[name='signInSubmitButton']").click
    expect(page).to have_content 'Home#index'
    expect(page).to have_content 'Pipeline Test 1'
  end

end
