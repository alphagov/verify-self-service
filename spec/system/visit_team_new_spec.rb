require 'rails_helper'

RSpec.describe 'New Team Page', type: :system do
  before(:each) do
    login_user
  end
  let(:team_name) { 'test team' }
  context 'creation succeeds' do
    it 'when a valid name' do
      visit new_admin_team_path
      fill_in 'team_name', with: team_name
      click_button 'Create Team'

      expect(page).to have_content 'Teams'
      expect(page).to have_content team_name
    end
  end

  context 'creation fails' do
    it 'when name is not specified' do
      visit new_admin_team_path
      click_button 'Create Team'

      expect(page).to have_content 'Add a Team'
      expect(page).to have_content "Name can't be blank"
    end

    it 'when name is not unique' do
      visit new_admin_team_path
      fill_in 'team_name', with: team_name
      click_button 'Create Team'

      visit new_admin_team_path
      fill_in 'team_name', with: team_name
      click_button 'Create Team'

      expect(page).to have_content 'Add a Team'
      expect(page).to have_content 'Name has already been taken'
    end
  end
end
