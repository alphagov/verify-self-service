require 'rails_helper'

RSpec.describe 'Sign in', type: :system do
  scenario 'user cannot sign in if not registered' do
    sign_in('unregistered@example.com', 'testtest')

    expect(current_path).to eql new_user_session_path
    expect(page).to have_content 'Invalid Username or Password.'
  end

  scenario 'user can sign in with valid credentials' do
    user = FactoryBot.create(:user)
    sign_in(user.email, user.password)

    expect(current_path).to eql root_path
    expect(page).to have_content 'Signed in successfully.'
  end

  scenario 'user cannot sign in with wrong email' do
    user = FactoryBot.create(:user)
    sign_in('invalid@email.com', user.password)

    expect(current_path).to eql new_user_session_path
    expect(page).to have_content 'Invalid Username or Password.'
  end

  scenario 'user cannot sign in with wrong password' do
    user = FactoryBot.create(:user)
    sign_in(user.email, 'invalidpassword')

    expect(current_path).to eql new_user_session_path
    expect(page).to have_content 'Invalid Username or Password.'
  end

  scenario 'user cannot access pages if not signed in' do
    visit new_msa_component_path

    expect(current_path).to eql new_user_session_path
    expect(page).to have_content 'You need to sign in or sign up before continuing.'
  end
end
