require 'rails_helper'

RSpec.describe 'Homepage', type: :system do
  it 'shows greeting with JS', js: true do
    visit 'https://verify-self-service-dev.cloudapps.digital/home/index'
    expect(page).to have_content 'Home#index'
  end
end
