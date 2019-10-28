require 'rails_helper'

RSpec.describe 'Cookies Page', type: :system do
  it 'displays the page when not logged in' do
    visit cookies_path
    expect(page).to have_content 'We store session cookies on your computer to help keep your information secure while you use the service.'
  end

  it 'displays the page when logged in' do
    login_user
    visit cookies_path
    expect(page).to have_content 'We store session cookies on your computer to help keep your information secure while you use the service.'
  end
end