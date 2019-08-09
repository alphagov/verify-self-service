require 'rails_helper'

RSpec.describe ProfileController, type: :controller do
  describe "Login Successfully" do
    it "redirect to login if no user" do
      get :show
      expect(response.status).to eq(302)
    end

    it "get profile if have user" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      user = FactoryBot.create(:user)
      allow(request.env['warden']).to receive(:authenticate!).and_return(@user)
      allow(controller).to receive(:current_user).and_return(@user)
      sign_in user
      get :show
      expect(response.status).to eq(200)
    end
  end
end
