require 'rails_helper'

RSpec.describe 'Profile page', type: :system do
  before(:each) do
    login_user
  end

  context 'profile page' do
    it 'should show profile page' do
      visit profile_path
      expect(page).to have_content t('profile.title')
      expect(current_path).to eql profile_path
    end
  end
end
