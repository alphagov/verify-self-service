require 'rails_helper'
include CognitoSupport

RSpec.describe 'Header Navigation', type: :system do
  it 'displays admin link for admin user' do
    login_gds_user
    visit root_path

    expect(page).to have_css('.govuk-header__content', text: 'Admin')
  end

  it 'does not display admin link for non admin user' do
    login_certificate_manager_user
    visit root_path

    expect(page).not_to have_css('.govuk-header__content', text: 'Admin')
  end

  it 'displays header links' do
    login_certificate_manager_user
    visit root_path

    expect(page).to have_css('.govuk-header__content', text: 'Documentation')
    expect(page).to have_css('.govuk-header__content', text: 'Support')
    expect(page).to have_css('.govuk-header__content', text: 'Your profile')
    expect(page).to have_css('.govuk-header__content', text: 'Sign out')
  end
end
