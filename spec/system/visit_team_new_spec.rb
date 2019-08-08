require 'rails_helper'

RSpec.describe 'New Team Page', type: :system do
  before(:each) do
    login_gds_user
  end
  let(:team_name) { 'test team' }
  context 'creation succeeds' do
    it 'when a valid name' do
      visit new_team_path
      fill_in 'team_name', with: team_name
      click_button t('team.new.create_team')

      expect(page).to have_content t('team.heading')
      expect(page).to have_content team_name
    end
  end

  context 'creation fails' do
    it 'when name is not specified' do
      visit new_team_path
      click_button t('team.new.create_team')

      expect(page).to have_content t('team.new.heading')
      expect(page).to have_content t('common.error_blank_name')
    end

    it 'when name is not unique' do
      visit new_team_path
      fill_in 'team_name', with: team_name
      click_button t('team.new.create_team')

      visit new_team_path
      fill_in 'team_name', with: team_name
      click_button t('team.new.create_team')

      expect(page).to have_content t('team.new.heading')
      expect(page).to have_content t('common.error_name_not_unique')
    end
  end
end
