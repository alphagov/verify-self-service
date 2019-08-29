require 'rails_helper'

RSpec.describe HealthcheckController, type: :controller do
  describe 'GET #index' do
    it 'returns success statuses when healthchecks pass' do
      allow_any_instance_of(Healthcheck::CognitoCheck).to receive(:status).and_return(:ok)
      allow_any_instance_of(Healthcheck::DbCheck).to receive(:status).and_return(:ok)
      allow_any_instance_of(Healthcheck::StorageCheck).to receive(:status).and_return(:ok)

      get :index
      json_response = JSON.parse(response.body)

      expect(response).to have_http_status(:success)
      expect(json_response['status']).to eq('ok')
      json_response['checks'].each do |_, check_status|
        expect(check_status['status']).to eq('ok')
      end
    end

    it 'returns critical statuses when healthchecks fail' do
      allow_any_instance_of(
        Healthcheck::CognitoCheck
      ).to receive(:status).and_raise(Aws::CognitoIdentityProvider::Errors::ServiceError)
      allow_any_instance_of(
        Healthcheck::DbCheck
      ).to receive(:status).and_raise(ActiveRecord::ConnectionNotEstablished)
      allow_any_instance_of(
        Healthcheck::StorageCheck
      ).to receive(:status).and_raise(Aws::S3::Errors::ServiceError)

      get :index
      json_response = JSON.parse(response.body)

      expect(response).to have_http_status(:service_unavailable)
      expect(json_response['status']).to eq('service_unavailable')
      json_response['checks'].each do |_, check_status|
        expect(check_status['status']).to eq('service_unavailable')
      end
    end
  end
end
