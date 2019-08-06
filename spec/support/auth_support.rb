require 'rails_helper'

module AuthSupport

  def user_stub_auth
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @user = FactoryBot.create(:user)
    stub_auth
  end

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

  def certmgr_stub_auth
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @user = FactoryBot.create(:certificate_manager_user)
    stub_auth
  end

  def stub_auth
    allow(request.env['warden']).to receive(:authenticate!).and_return(@user)
    allow(controller).to receive(:current_user).and_return(@user)
    sign_in(@user, scope: :user)
  end
end
