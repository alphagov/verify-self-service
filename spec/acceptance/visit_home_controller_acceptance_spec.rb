require 'acceptance_helper'

RSpec.describe 'Homepage', type: :feature, acceptance: true do

  it 'shows greeting with JS', js: true do
    #visit "https://#{ENV["TEST_URL"]}/home/index"
    visit "https://verify-self-service-dev.cloudapps.digital/home/index"
    expect(page).to have_content 'Home#index'
    expect(page).to have_content 'Pipeline Test 1'
  end
  
end
