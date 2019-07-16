require 'rails_helper'

RSpec.describe 'IndexPage', type: :system do
  before(:each) do
    login_user
  end
  it 'shows greeting without JS' do
    visit '/'
    expect(page).to have_content 'Components'
  end

  it 'shows greeting with JS', js: true do
    visit '/'
    expect(page).to have_content 'Components'
  end
end
