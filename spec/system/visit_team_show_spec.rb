require 'rails_helper'

RSpec.describe 'Team Show Page', type: :system do
  include CognitoSupport

  before(:each) do
    login_gds_user
  end

  it 'displays the team show page' do
    visit team_path(Team.first.id)
    expect(page).to have_content (Team.first.id)
    expect(page).to have_content (Team.first.team_alias)
    expect(page).to have_content (Team.first.created_at)
    expect(page).to have_content (Team.first.updated_at)
  end
end
