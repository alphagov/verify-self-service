require 'rails_helper'

RSpec.describe 'ChangePassword', type: :system do
  before(:each) do
    login_gds_user
  end

  it 'shows form' do
    visit profile_change_password_path()
    expect(page).to have_content 'Old password'
  end

  it 'shows errors when an empty form is submitted' do
    visit profile_change_password_path()
    click_button 'Change password'
    forms = page.find("#new_form > fieldset")
    expect(forms).to have_content "Old password can't be blank"
    expect(forms).to have_content "Password can't be blank"
    expect(forms).to have_content "Password confirmation can't be blank"
  end
end

