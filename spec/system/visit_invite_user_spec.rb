require 'rails_helper'

RSpec.describe 'InviteToTeam', type: :system do
  before(:each) do
    login_gds_user
  end

  it 'shows form' do
    visit invite_to_team_path(Team.first.id)
    expect(page).to have_content 'Invite a new user'
  end

  it 'shows errors when an empty form is submitted' do
    visit invite_to_team_path(Team.first.id)
    click_button 'Invite user'
    expect(page).to have_content "Email can't be blank"
    expect(page).to have_content "Given name can't be blank"
    expect(page).to have_content "Family name can't be blank"
  end
end