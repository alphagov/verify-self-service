require 'rails_helper'

RSpec.describe 'InviteToTeam', type: :system do
  before(:each) do
    login_gds_user
  end

  it 'shows form' do
    visit invite_to_team_path(Team.first.id)
    expect(page).to have_content 'Invite a new user'
  end

  it 'submits the form correctly without error' do
    stub_cognito_response(method: :admin_create_user, payload: { user: { username:'test@test.test' } })
    visit invite_to_team_path(Team.first.id)
    fill_in 'invite_user_form_email', with: 'test@test.com'
    fill_in 'invite_user_form_given_name', with: "test"
    fill_in 'invite_user_form_family_name', with: "User"
    check 'invite_user_form_roles_certmgr'
    check 'invite_user_form_roles_usermgr'
    click_button 'Invite user'
    expect(current_path).to eql users_path
    expect(page).to have_content t('users.invite.success')
  end

  it 'shows errors when an empty form is submitted' do
    visit invite_to_team_path(Team.first.id)
    click_button 'Invite user'
    expect(page).to have_content "Email can't be blank"
    expect(page).to have_content "Given name can't be blank"
    expect(page).to have_content "Family name can't be blank"
  end
end