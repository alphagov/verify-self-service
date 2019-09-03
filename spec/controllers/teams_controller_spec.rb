require 'rails_helper'
RSpec.describe TeamsController, type: :controller do
  include AuthSupport, CognitoSupport

  before(:each) do
    gdsuser_stub_auth
  end

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #new" do
    it "returns http success" do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    let(:team_name) { 'super-awesome-team' }

    it 'successfully creates a group in cognito' do
      Rails.configuration.cognito_user_pool_id = 'dummy'
      stub_cognito_response(
        method: :create_group,
        payload: {
          group: {
            group_name: team_name,
            user_pool_id: Rails.configuration.cognito_user_pool_id,
            description: team_name
          }
        }
      )
      post :create, params: { team: { name: team_name } }

      expect(subject).to redirect_to(teams_path)
      expect(flash.now[:errors]).to be_nil
      expect(flash.now[:success]).not_to be_nil
    end

    it 'fails to create a group in cognito' do
      Rails.configuration.cognito_user_pool_id = 'dummy'
      stub_cognito_response(
        method: :create_group,
        payload: Aws::CognitoIdentityProvider::Errors::InvalidParameterException.new("error", "error", {})
      )
      post :create, params: { team: { name: 'not a valid team name' } }

      expect(response).to have_http_status(:success)
      expect(flash.now[:errors]).not_to be_nil
      expect(flash.now[:success]).to be_nil
    end
  end
end
