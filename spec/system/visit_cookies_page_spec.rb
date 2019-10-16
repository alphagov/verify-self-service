require 'rails_helper'

RSpec.describe 'Cookies Page', type: :system do
  it 'displays the page' do
    visit cookies_path
    expect(page).to have_content 'We store session cookies on your computer to help keep your information secure while you use the service.'
  end
end