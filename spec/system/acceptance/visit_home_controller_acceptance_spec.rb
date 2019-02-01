require 'rails_helper'

RSpec.describe 'Homepage', type: :system, acceptance: true do

  it 'shows greeting with JS', js: true do
    visit "https://#{ENV["TEST_URL"]}/home/index"
    expect(page).to have_content 'Home#index'
  end
  
end
