require 'rails_helper'

RSpec.describe 'Update user name page', type: :system do
  before(:each) do
    login_user
    stub_cognito_response(method: :update_user_attributes, payload: {})  
  end
  
  context '#update_user_name' do
    it 'renders update user name page' do
      visit update_user_name_path
      expect(page).to have_content t('users.update_name.title')
      expect(current_path).to eql update_user_name_path
    end

    it 'successfully changes user name' do
      visit update_user_name_path
      fill_in 'update_user_name_form[first_name]', with: 'Joe'
      fill_in 'update_user_name_form[last_name]', with: 'Bloggs' 
      click_button t('users.update_name.save') 
      expect(current_path).to eql profile_path
    end
  end
end
