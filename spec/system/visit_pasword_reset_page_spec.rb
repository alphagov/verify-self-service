require 'rails_helper'

RSpec.describe 'Forgotten password flow', type: :system do

  it 'successfully renders the forgotten password page' do
    visit forgot_password_path

    expect(page).to have_field 'forgotten_password_form_email'
    expect(page).to have_content t('password.forgot_link')
  end

  it 'successfully renders the password reset page' do
    visit reset_password_path

    expect(page).to have_field 'password_recovery_form[code]'
    expect(page).to have_field 'password_recovery_form[password]'
    expect(page).to have_field 'password_recovery_form[password_confirmation]'
    expect(page).to have_content t('password.reset_password_heading')
  end

  it 'successfully goes through' do
    visit forgot_password_path
    fill_in 'forgotten_password_form_email', with: 'test@test.com'
    click_button t('password.request_reset')
    fill_in 'password_recovery_form[code]', with: '1234'
    fill_in 'password_recovery_form[password]', with: '12345678'
    fill_in 'password_recovery_form[password_confirmation]', with: '12345678'
    click_button t('password.change_password_btn')
    expect(current_path).to eql new_user_session_path
  end
end
