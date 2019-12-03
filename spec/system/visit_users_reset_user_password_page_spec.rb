require 'rails_helper'

RSpec.describe 'Reset user password page', type: :system do
  include CognitoSupport

  let(:member_user_id) { SecureRandom::uuid }
  let(:member_first_name) { 'Tester' }
  let(:member_family_name) { 'Testerator' }
  let(:member_email) { 'test@test.com' }

  let(:cognito_user) {
    { username: member_user_id,
      user_attributes: [{name: "given_name", value: member_first_name},
                        {name: "family_name", value: member_family_name},
                        {name: "email", value: member_email},
                        {name: "custom:roles", value: "certmgr"}]}
  }

  let(:cognito_users) {
    { users: [
      { username: member_user_id,
        attributes: [{name: "given_name", value: member_first_name},
                          {name: "family_name", value: member_family_name},
                          {name: "email", value: member_email},
                          {name: "custom:roles", value: "certmgr"}]}
      ]}
    }

  before(:each) do
    stub_cognito_response(method: :admin_get_user, payload: cognito_user)
  end

  context 'GDS user' do
    before(:each) do
      login_gds_user
    end

    it 'renders the page and resets the members password' do
      visit reset_user_password_path(user_id: member_user_id)
      expect(page).to have_content t('users.reset_user_password.heading', name: member_first_name + ' ' + member_family_name)
      click_link t('users.reset_user_password.confirm')
      expect(current_path).to eql users_path
    end
  end

  context 'User Manager' do
    before(:each) do
      user = FactoryBot.create(:user_manager_user)
      login_as(user, scope: :user)
      stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
    end

    it 'renders the page and rests the members password' do
      visit reset_user_password_path(user_id: member_user_id)
      expect(page).to have_content t('users.reset_user_password.heading', name: member_first_name + ' ' + member_family_name)
      click_link t('users.reset_user_password.confirm')
      expect(current_path).to eql users_path
    end
  end
end
