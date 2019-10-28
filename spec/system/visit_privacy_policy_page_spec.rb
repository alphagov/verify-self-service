require 'rails_helper'

RSpec.describe 'Privacy policy Page', type: :system do
  it 'displays the page when not logged in' do
    visit privacy_notice_path
    expect(page).to have_content 'This privacy notice explains what data we might collect, how it’s used and how it’s protected.'
  end

  it 'displays the page when logged in' do
    login_user
    visit privacy_notice_path
    expect(page).to have_content 'This privacy notice explains what data we might collect, how it’s used and how it’s protected.'
  end
end
