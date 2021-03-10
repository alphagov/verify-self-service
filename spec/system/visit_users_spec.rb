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
  let(:team_rp) { create(:new_team_event, team_type: 'rp') }
  let(:team_idp) { create(:new_team_event, team_type: 'idp') }
  let(:team_other) { create(:new_team_event, team_type: 'other') }

  let(:create_teams) { team_apple
                       team_banana
                       team_cherry
                       team_rp
                       team_idp
                       team_other
                      }
  let(:cognito_users) {
  {users: [
      {username: "111",
        user_status: 'CONFIRMED',
        attributes: [{name: "given_name", value: "Apple"},
                    {name: "family_name", value: "One"},
                    {name: "email", value: "apple.one@test.com"},
                    {name: "custom:roles", value: "usermgr"}
        ]},
      {username: "222",
        user_status: 'FORCE_CHANGE_PASSWORD',
        attributes: [{name: "given_name", value: "Apple"},
                    {name: "family_name", value: "Two"},
                    {name: "email", value: "apple.two@test.com"},
                    {name: "custom:roles", value: "certmgr,usermgr"}
        ]},
      {username: "333",
        user_status: 'COMPROMISED',
        attributes: [{name: "given_name", value: "Apple"},
                    {name: "family_name", value: "Three"},
                    {name: "email", value: "apple.three@test.com"},
                    {name: "custom:roles", value: "certmgr"}
        ]},
        {username: "444",
        user_status: 'RESET_REQUIRED',
        attributes: [{name: "given_name", value: "Apple"},
                      {name: "family_name", value: "Four"},
                      {name: "email", value: "apple.four@test.com"},
                      {name: "custom:roles", value: "certmgr"}
        ]}
        ]}
  }
  let(:visible_statuses) { %w(FORCE_CHANGE_PASSWORD RESET_REQUIRED)}


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
      expect(page).to have_link(team_rp.name)
      expect(page).to have_link(team_idp.name)
      expect(page).to have_link(team_other.name)
    end

    it 'shows links to download csv lists' do
      visit users_path
      expect(page).to have_content t('users.download_csv_list', team_type: TEAMS::RP.upcase)
      expect(page).to have_content t('users.download_csv_list', team_type: TEAMS::IDP.upcase)
      expect(page).to have_content t('users.download_csv_list', team_type: TEAMS::ALL.upcase)
    end
  end

  context 'User Manager' do
    before(:each) do
      user = FactoryBot.create(:user_manager_user, team: team_apple.team.id)
      login_as(user, scope: :user)
      stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
    end

    it 'shows team members' do
      visit users_path
      expect(page).to have_content t('users.title_for_team')+' '+team_apple.name
      cognito_users[:users].each do |user|
        if visible_statuses.include?(user[:user_status])
          expect(page).to have_content(t("users.status.#{user[:user_status]}"))
        else
          expect(page).not_to have_content(t("users.status.#{user[:user_status]}"))
        end

        expect(page).to have_content(user[:attributes][0][:value] +' '+ user[:attributes][1][:value] )
        within("##{user[:username]}") do
          expect(page).to have_content((user[:attributes][3][:value].split(',').include?(ROLE::CERTIFICATE_MANAGER) ? 'Can' : 'Cannot' ) + ' ' + t('users.roles.certmgr'))
          expect(page).to have_content((user[:attributes][3][:value].split(',').include?(ROLE::USER_MANAGER) ? 'Can' : 'Cannot' ) + ' ' + t('users.roles.usermgr'))
        end
      end
    end
  end

  context 'RP User' do
    before(:each) do
      user = FactoryBot.create(:rp_user_manager_user, team: team_rp.team.id)
      login_as(user, scope: :user)
      stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
    end

    it 'shows team members' do
      visit users_path
      expect(page).to have_content t('users.title_for_team')+' '+team_rp.name
      cognito_users[:users].each do |user|
        if visible_statuses.include?(user[:user_status])
          expect(page).to have_content(t("users.status.#{user[:user_status]}"))
        else
          expect(page).not_to have_content(t("users.status.#{user[:user_status]}"))
        end

        expect(page).to have_content(user[:attributes][0][:value] +' '+ user[:attributes][1][:value] )
        within("##{user[:username]}") do
          expect(page).to have_content((user[:attributes][3][:value].split(',').include?(ROLE::CERTIFICATE_MANAGER) ? 'Can' : 'Cannot' ) + ' ' + t('users.roles.certmgr'))
          expect(page).to have_content((user[:attributes][3][:value].split(',').include?(ROLE::USER_MANAGER) ? 'Can' : 'Cannot' ) + ' ' + t('users.roles.usermgr'))
        end
      end
    end

    it 'does not shows links to download csv lists' do
      visit users_path
      expect(page).to_not have_content t('users.download_csv_list', team_type: TEAMS::RP.upcase)
      expect(page).to_not have_content t('users.download_csv_list', team_type: TEAMS::IDP.upcase)
      expect(page).to_not have_content t('users.download_csv_list', team_type: TEAMS::ALL.upcase)
    end
  end

  context 'IDP User' do
    before(:each) do
      user = FactoryBot.create(:idp_user_manager_user, team: team_idp.team.id)
      login_as(user, scope: :user)
      stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
    end

    it 'shows team members' do
      visit users_path
      expect(page).to have_content t('users.title_for_team')+' '+team_idp.name
      cognito_users[:users].each do |user|
        if visible_statuses.include?(user[:user_status])
          expect(page).to have_content(t("users.status.#{user[:user_status]}"))
        else
          expect(page).not_to have_content(t("users.status.#{user[:user_status]}"))
        end

        expect(page).to have_content(user[:attributes][0][:value] +' '+ user[:attributes][1][:value] )
        within("##{user[:username]}") do
          expect(page).to_not have_content((user[:attributes][3][:value].split(',').include?(ROLE::CERTIFICATE_MANAGER) ? 'Can' : 'Cannot' ) + ' ' + t('users.roles.certmgr'))
          expect(page).to have_content((user[:attributes][3][:value].split(',').include?(ROLE::USER_MANAGER) ? 'Can' : 'Cannot' ) + ' ' + t('users.roles.usermgr'))
        end
      end
    end

    it 'does not shows links to download csv lists' do
      visit users_path
      expect(page).to_not have_content t('users.download_csv_list', team_type: TEAMS::RP.upcase)
      expect(page).to_not have_content t('users.download_csv_list', team_type: TEAMS::IDP.upcase)
      expect(page).to_not have_content t('users.download_csv_list', team_type: TEAMS::ALL.upcase)
    end
  end
end
