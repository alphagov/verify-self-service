require 'rails_helper'

RSpec.describe 'Users Page', type: :system do
  include CognitoSupport

  let(:visible_statuses) { %w(FORCE_CHANGE_PASSWORD RESET_REQUIRED)}

  context 'GDS user' do
    let(:team_rp) { create(:team, team_type: 'rp') }
    let(:team_idp) { create(:team, team_type: 'idp') }
    let(:create_teams) { team_rp
                         team_idp}

    let(:rp_team_member) { create(:idp_user_manager_user, email: 'rp@t.com', team: team_rp.id) }
    let(:idp_team_member) { create(:idp_user_manager_user, email: 'idp@t.com', team: team_idp.id) }

    let(:cognito_rp_users) {
      { users: [
        { username: rp_team_member.user_id,
          attributes: [{name: "given_name", value: rp_team_member.first_name},
                            {name: "family_name", value: rp_team_member.last_name},
                            {name: "email", value: rp_team_member.email},
                            {name: "custom:roles", value: "certmgr"}]}
      ]}
    }

    let(:cognito_idp_users) {
      { users: [
        { username: idp_team_member.user_id,
          attributes: [{name: "given_name", value: idp_team_member.first_name},
                            {name: "family_name", value: idp_team_member.last_name},
                            {name: "email", value: idp_team_member.email},
                            {name: "custom:roles", value: "usermgr"}]}
      ]}
    }

    before(:each) do
      login_gds_user
    end

    it 'shows all teams' do
      stub_cognito_response(method: :list_users_in_group, payload: cognito_rp_users)
      stub_cognito_response(method: :list_users_in_group, payload: cognito_idp_users)

      visit users_path
      expect(page).to have_content t('team.heading')
      expect(page).to have_link(team_rp.name)
      expect(page).to have_link(team_idp.name)
    end

    it 'shows links to download csv lists' do
      visit users_path
      expect(page).to have_content t('users.download_csv_list', team_type: TEAMS::RP.upcase)
      expect(page).to have_content t('users.download_csv_list', team_type: TEAMS::IDP.upcase)
      expect(page).to have_content t('users.download_csv_list', team_type: TEAMS::ALL.upcase)
    end

    it 'does show manage certificates role option for rp team members' do
      stub_cognito_response(method: :list_users_in_group, payload: cognito_rp_users)

      visit users_path
      expect(page).to have_content t('team.heading')
      expect(page).to have_link(team_rp.name)
      click_link team_rp.name
      expect(page).to have_content(team_rp.name)
      expect(page).to have_css('table', text: t('users.roles.usermgr'))
      expect(page).to have_css('table', text: t('users.roles.certmgr'))
    end

    it 'does not show manage certificates role option for idp team members' do
      stub_cognito_response(method: :list_users_in_group, payload: cognito_idp_users)

      visit users_path
      expect(page).to have_content t('team.heading')
      expect(page).to have_link(team_idp.name)
      click_link team_idp.name
      expect(page).to have_content(team_idp.name)
      expect(page).to have_css('table', text: t('users.roles.usermgr'))
      expect(page).to_not have_css('table', text: t('users.roles.certmgr'))
    end

  end

  context 'RP User' do
    let(:team_rp) { create(:team, team_type: 'rp') }
    let(:create_teams) { team_rp}
  
    let(:rp_team_member_1) { create(:idp_user_manager_user, email: 't1@t.com', team: team_rp.id) }
    let(:rp_team_member_2) { create(:idp_user_manager_user, email: 't2@t.com', team: team_rp.id) }
    let(:rp_team_member_3) { create(:idp_user_manager_user, email: 't3@t.com', team: team_rp.id) }
    let(:rp_team_member_4) { create(:idp_user_manager_user, email: 't4@t.com', team: team_rp.id) }
  
    let(:cognito_users) {
    {users: [
        {username: "111",
          user_status: 'CONFIRMED',
          attributes: [{name: "given_name", value: rp_team_member_1.first_name},
                      {name: "family_name", value: rp_team_member_1.last_name},
                      {name: "email", value: rp_team_member_1.email},
                      {name: "custom:roles", value: "certmgr"}
          ]},
        {username: "222",
          user_status: 'FORCE_CHANGE_PASSWORD',
           attributes: [{name: "given_name", value: rp_team_member_2.first_name},
                      {name: "family_name", value: rp_team_member_2.last_name},
                      {name: "email", value: rp_team_member_2.email},
                      {name: "custom:roles", value: "usermgr"}
          ]},
        {username: "333",
          user_status: 'COMPROMISED',
          attributes: [{name: "given_name", value: rp_team_member_3.first_name},
                      {name: "family_name", value: rp_team_member_3.last_name},
                      {name: "email", value: rp_team_member_3.email},
                      {name: "custom:roles", value: "certmgr"}
          ]},
          {username: "444",
          user_status: 'RESET_REQUIRED',
          attributes: [{name: "given_name", value: rp_team_member_4.first_name},
                      {name: "family_name", value: rp_team_member_4.last_name},
                      {name: "email", value: rp_team_member_4.email},
                      {name: "custom:roles", value: "usermgr"}
          ]}
          ]}
    }

    it 'shows team members' do
      user = FactoryBot.create(:idp_user_manager_user, team: team_rp.id)
      login_as(user, scope: :user)
      stub_cognito_response(method: :list_users_in_group, payload: cognito_users)

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
    let(:team_idp) { create(:team, team_type: 'idp') }
    let(:create_teams) { team_idp}
  
    let(:idp_team_member_1) { create(:idp_user_manager_user, email: 't1@t.com', team: team_idp.id) }
    let(:idp_team_member_2) { create(:idp_user_manager_user, email: 't2@t.com', team: team_idp.id) }
    let(:idp_team_member_3) { create(:idp_user_manager_user, email: 't3@t.com', team: team_idp.id) }
    let(:idp_team_member_4) { create(:idp_user_manager_user, email: 't4@t.com', team: team_idp.id) }
  
    let(:cognito_users) {
    {users: [
        {username: "111",
          user_status: 'CONFIRMED',
          attributes: [{name: "given_name", value: idp_team_member_1.first_name},
                      {name: "family_name", value: idp_team_member_1.last_name},
                      {name: "email", value: idp_team_member_1.email},
                      {name: "custom:roles", value: "usermgr"}
          ]},
        {username: "222",
          user_status: 'FORCE_CHANGE_PASSWORD',
           attributes: [{name: "given_name", value: idp_team_member_2.first_name},
                      {name: "family_name", value: idp_team_member_2.last_name},
                      {name: "email", value: idp_team_member_2.email},
                      {name: "custom:roles", value: "usermgr"}
          ]},
        {username: "333",
          user_status: 'COMPROMISED',
          attributes: [{name: "given_name", value: idp_team_member_3.first_name},
                      {name: "family_name", value: idp_team_member_3.last_name},
                      {name: "email", value: idp_team_member_3.email},
                      {name: "custom:roles", value: "usermgr"}
          ]},
          {username: "444",
          user_status: 'RESET_REQUIRED',
          attributes: [{name: "given_name", value: idp_team_member_4.first_name},
                      {name: "family_name", value: idp_team_member_4.last_name},
                      {name: "email", value: idp_team_member_4.email},
                      {name: "custom:roles", value: "usermgr"}
          ]}
          ]}
    }

    it 'shows team members' do
      user = FactoryBot.create(:idp_user_manager_user, team: team_idp.id)
      login_as(user, scope: :user)
      stub_cognito_response(method: :list_users_in_group, payload: cognito_users)

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
