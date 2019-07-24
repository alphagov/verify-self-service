require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  describe "Login Successfully" do
    it "redirect to login if no user" do
      get :show
      expect(response.status).to eq(302)
    end

    it "get dashboard if have user" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      user = FactoryBot.create(:user)
      sign_in user
      get :show
      expect(response.status).to eq(200)
    end
  end
end
