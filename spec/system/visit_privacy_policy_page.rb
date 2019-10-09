require 'rails_helper'

RSpec.describe 'Privacy policy Page', type: :system do
  it 'displays the page' do
    visit privacy_policy_path
    expect(page).to have_content 'This privacy notice explains what data we might collect, how it’s used and how it’s protected.'
  end
end