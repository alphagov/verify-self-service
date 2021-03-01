require 'rails_helper'

RSpec.describe 'Update user Page', type: :system do
  include CognitoSupport


  context 'GDS user' do
    let(:team_rp) { create(:team, team_type: 'rp') }
    let(:team_idp) { create(:team, team_type: 'idp') }
    let(:create_teams) { team_rp
                         team_idp}
    let(:idp_team_member) { create(:idp_user_manager_user, first_name: 'IDP USER' ,team: team_idp.id) }
    let(:rp_team_member) { create(:rp_user_manager_user, first_name: 'RP USER', team: team_rp.id) }

    let(:cognito_rp_user) {
      { username: rp_team_member.user_id,
        user_attributes: [{name: "given_name", value: rp_team_member.first_name},
                          {name: "family_name", value: rp_team_member.last_name},
                          {name: "email", value: rp_team_member.email},
                          {name: "custom:roles", value: "certmgr"}]}
    }

    let(:cognito_rp_users) {
        { users: [
          { username: rp_team_member.user_id,
            attributes: [{name: "given_name", value: rp_team_member.first_name},
                              {name: "family_name", value: rp_team_member.last_name},
                              {name: "email", value: rp_team_member.email},
                              {name: "custom:roles", value: "certmgr"}]}
        ]}
    }

    let(:cognito_idp_user) {
      { username: idp_team_member.user_id,
        user_attributes: [{name: "given_name", value: idp_team_member.first_name},
                          {name: "family_name", value: idp_team_member.last_name},
                          {name: "email", value: idp_team_member.email},
                          {name: "custom:roles", value: "usermgr"}]}
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

    it 'renders the page' do
      stub_cognito_response(method: :admin_get_user, payload: cognito_rp_user)

      visit update_user_path(user_id: rp_team_member.user_id )
      expect(page).to have_title t('users.show.title', name: rp_team_member.first_name + ' ' + rp_team_member.last_name)
      expect(page).to have_content rp_team_member.first_name + ' ' + rp_team_member.last_name
    end

    it 'does not show manage certificates role option when updating idp team user' do
      stub_cognito_response(method: :admin_get_user, payload: cognito_idp_user)
      stub_cognito_response(method: :list_users_in_group, payload: cognito_idp_users)

      visit users_path
      expect(page).to have_content t('team.heading')
      click_link team_idp.name
      expect(page).to have_content(team_idp.name)
      expect(page).to have_css('table', text: t('users.roles.usermgr'))
      expect(page).to_not have_css('table', text: t('users.roles.certmgr'))
      find('#' + idp_team_member.user_id).click_link(t('users.change_details'))
      expect(page).to have_title t('users.show.title', name: idp_team_member.first_name + ' ' + idp_team_member.last_name)
      expect(page).to_not have_css('fieldset', text: t('users.roles.certmgr'))
      expect(page).to have_css('fieldset', text: t('users.roles.usermgr'))
    end

    it 'does show manage certificates role option when updating rp team user' do
      stub_cognito_response(method: :admin_get_user, payload: cognito_rp_user)
      stub_cognito_response(method: :list_users_in_group, payload: cognito_rp_users)

      visit users_path
      expect(page).to have_content t('team.heading')
      click_link team_rp.name
      expect(page).to have_content(team_rp.name)
      expect(page).to have_css('table', text: t('users.roles.usermgr'))
      expect(page).to have_css('table', text: t('users.roles.certmgr'))
      find('#' + rp_team_member.user_id).click_link(t('users.change_details'))
      expect(page).to have_title t('users.show.title', name: rp_team_member.first_name + ' ' + rp_team_member.last_name)
      expect(page).to have_css('fieldset', text: t('users.roles.certmgr'))
      expect(page).to have_css('fieldset', text: t('users.roles.usermgr'))
    end
  end

  context 'RP user' do
    let(:team_rp) { create(:team, team_type: 'rp') }
    let(:create_teams) { team_rp }
    let(:rp_team_member) { create(:rp_user_manager_user, first_name: 'RP USER', team: team_rp.id) }

    let(:cognito_rp_user) {
      { username: rp_team_member.user_id,
        user_attributes: [{name: "given_name", value: rp_team_member.first_name},
                          {name: "family_name", value: rp_team_member.last_name},
                          {name: "email", value: rp_team_member.email},
                          {name: "custom:roles", value: "certmgr"}]}
    }

    let(:cognito_rp_users) {
        { users: [
          { username: rp_team_member.user_id,
            attributes: [{name: "given_name", value: rp_team_member.first_name},
                              {name: "family_name", value: rp_team_member.last_name},
                              {name: "email", value: rp_team_member.email},
                              {name: "custom:roles", value: "certmgr"}]}
        ]}
    }

    before(:each) do
      login_rp_user
    end

    it 'shows team members with the certificate manager role option' do
      stub_cognito_response(method: :admin_get_user, payload: cognito_rp_user)
      stub_cognito_response(method: :list_users_in_group, payload: cognito_rp_users)

      visit update_user_path(user_id: rp_team_member.user_id, team_type: TEAMS::RP)
      expect(page).to have_content rp_team_member.first_name + ' ' + rp_team_member.last_name
      expect(page).to have_css('fieldset', text: t('users.roles.certmgr'))
      expect(page).to have_css('fieldset', text: t('users.roles.usermgr'))
    end
  end

  context 'IDP user' do
    let(:team_idp) { create(:team, team_type: 'idp') }
    let(:create_teams) { team_idp }
    let(:idp_team_member) { create(:idp_user_manager_user, first_name: 'IDP USER' ,team: team_idp.id) }

    let(:cognito_idp_user) {
      { username: idp_team_member.user_id,
        user_attributes: [{name: "given_name", value: idp_team_member.first_name},
                          {name: "family_name", value: idp_team_member.last_name},
                          {name: "email", value: idp_team_member.email},
                          {name: "custom:roles", value: "usermgr"}]}
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
      login_idp_user
    end

    it 'shows team members without the certificate manager role option' do
      stub_cognito_response(method: :admin_get_user, payload: cognito_idp_user)
      stub_cognito_response(method: :list_users_in_group, payload: cognito_idp_users)

      visit update_user_path(user_id: idp_team_member.user_id, team_type: TEAMS::IDP)
      expect(page).to have_content(idp_team_member.first_name + ' ' + idp_team_member.last_name)
      expect(page).to_not have_css('fieldset', text: t('users.roles.certmgr'))
      expect(page).to have_css('fieldset', text: t('users.roles.usermgr'))
    end
  end
end
