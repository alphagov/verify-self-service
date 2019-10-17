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
      expect(subject.instance_variable_get(:@team).errors[:team]).to eq([t('team.errors.failed')])
      expect(flash.now[:success]).to be_nil
    end
  end

  describe 'DELETE #destroy' do
    let(:team) { create(:team, name: 'super-awesome-team-soon-to-be-deleted') }

    it 'successfully deletes the team and group in cognito' do
      Rails.configuration.cognito_user_pool_id = 'dummy'
      stub_cognito_response( method: :delete_group, payload: {})
      expect_any_instance_of(AuthenticationBackend).to receive(:delete_group)

      delete :destroy, params: { id: team.id }

      expect(subject).to redirect_to(teams_path)
      expect(flash[:error]).to be_nil
      expect(Team.exists?(team.id)).to be false
    end

    it 'does not delete team if delete a group in cognito fails' do
      Rails.configuration.cognito_user_pool_id = 'dummy'
      stub_cognito_response(
        method: :delete_group,
        payload: 'ServiceError'
      )

      delete :destroy, params: { id: team.id }

      expect(subject).to redirect_to(teams_path)
      expect(flash[:error]).to include(t('team.errors.failed_to_delete'))
      expect(Team.exists?(team.id)).to be true
    end
  end
end
