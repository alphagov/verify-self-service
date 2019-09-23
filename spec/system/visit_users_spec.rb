require 'rails_helper'

RSpec.describe 'Users Page', type: :system do
  include CognitoSupport

  before(:each) do
    stub_cognito_response( method: :create_group, payload: {} )
    create_teams
  end

  let(:team_apple) { create(:new_team_event) }
  let(:team_banana) { create(:new_team_event) }
  let(:team_cherry) { create(:new_team_event) }
  let(:create_teams) { team_apple
                        team_banana
                        team_cherry }

  context 'GDS user' do
    before(:each) do
      login_gds_user
    end

    it 'shows all teams' do
      visit users_path
      expect(page).to have_content t('team.heading')
      expect(page).to have_link(team_apple.name)
      expect(page).to have_link(team_banana.name)
      expect(page).to have_link(team_cherry.name)
    end
  end

  context 'User Manager' do
    let(:cognito_users) {
      {users: [
          {username: "111",
           attributes: [{name: "given_name", value: "Apple"},
                        {name: "family_name", value: "One"},
                        {name: "email", value: "apple.one@test.com"},
                        {name: "custom:roles", value: "usermgr"}
           ]},
          {username: "222",
           attributes: [{name: "given_name", value: "Apple"},
                        {name: "family_name", value: "Two"},
                        {name: "email", value: "apple.two@test.com"},
                        {name: "custom:roles", value: "certmgr,usermgr"}
           ]},
          {username: "333",
           attributes: [{name: "given_name", value: "Apple"},
                        {name: "family_name", value: "Three"},
                        {name: "email", value: "apple.three@test.com"},
                        {name: "custom:roles", value: "certmgr"}
           ]}]}
    }


    before(:each) do
      user = FactoryBot.create(:user_manager_user, team: team_apple.team.id)
      login_as(user, scope: :user)
      stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
    end

    it 'shows team members' do
      visit users_path
      expect(page).to have_content t('users.title_for_team')+' '+team_apple.name
      cognito_users[:users].each do |user|
        expect(page).to have_content(user[:attributes][0][:value] +' '+ user[:attributes][1][:value] )
        within("##{user[:username]}") do
          expect(page).to have_content((user[:attributes][3][:value].split(',').include?(ROLE::CERTIFICATE_MANAGER) ? 'Can' : 'Cannot' ) + ' ' + t('users.roles.certmgr'))
          expect(page).to have_content((user[:attributes][3][:value].split(',').include?(ROLE::USER_MANAGER) ? 'Can' : 'Cannot' ) + ' ' + t('users.roles.usermgr'))
        end
      end
    end
  end


end
