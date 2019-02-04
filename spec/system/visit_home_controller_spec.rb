require 'rails_helper'

RSpec.describe 'Homepage', type: :system do
  it 'shows greeting without JS' do
    visit '/'
    expect(page).to have_content 'Home#index'
  end

  it 'shows greeting with JS', js: true do
    visit '/'
    expect(page).to have_content 'Home#index'
  end
end
