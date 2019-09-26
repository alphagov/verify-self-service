require 'rails_helper'

module AuthSupport

  def usermgr_stub_auth
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @user = FactoryBot.create(:user_manager_user)
    stub_auth
  end

  def compmgr_stub_auth
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @user = FactoryBot.create(:component_manager_user)
    stub_auth
  end

  def certmgr_stub_auth(team = nil)
    @request.env["devise.mapping"] = Devise.mappings[:user]
    team = FactoryBot.create(:team) if team.nil?
    @user = FactoryBot.create(:certificate_manager_user, team: team.id)
    stub_auth
  end

  def gdsuser_stub_auth
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @user = FactoryBot.create(:gds_user)
    stub_auth
  end

  def stub_auth
    allow(request.env['warden']).to receive(:authenticate!).and_return(@user)
    allow(controller).to receive(:current_user).and_return(@user)
    sign_in(@user, scope: :user)
  end
end
