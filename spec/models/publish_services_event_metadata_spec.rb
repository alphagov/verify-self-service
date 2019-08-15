require 'yaml'
require 'rails_helper'

RSpec.describe PublishServicesMetadataEvent, type: :model do
  let(:published_at) { Time.now }
  let(:event_id) { 0 }
  let(:component) { MsaComponent.create(name: 'lala', entity_id: 'https//test-entity') }
  let(:event) { PublishServicesMetadataEvent.create(event_id: event_id) }

  context '#create' do
    it 'creates a valid event which contains hard-coded data' do
      expect(event.data).to include(
        'event_id',
        'services_metadata'
      )
      expect(event.data['services_metadata']).to include('published_at')
    end

    it 'when event_id is blank services_metadata json is empty' do
      invalid_event = PublishServicesMetadataEvent.create
      event_error = invalid_event.errors.messages[:event_id]
      expect(invalid_event).to_not be_valid
      expect(invalid_event.data).to be_empty
      expect(event_error).to include("can't be blank")
    end

    it 'downloaded content is the same as upload with given key' do
      event.upload
      key = 'verify_services_metadata.json'
      expected_chunks = event.metadata

      actual_chunks = []
      SelfService.service(:storage_client).download key do |chunk|
        actual_chunks << chunk
      end

      expect(expected_chunks.to_json).to eq(actual_chunks.first)
    end
  end

  context 'upload' do
    before do
      SelfService.register_service(
        name: :integration_storage_client,
        client: ActiveStorage::Service.configure(
          Rails.configuration.active_storage.service,
          configuration('integration_storage.yml')
        )
      )
    end

    it 'when environment is set to integration on component' do
      expect(
        SelfService.service(:integration_storage_client)
      ).to receive(:upload)
      expect(
        SelfService.service(:storage_client)
      ).not_to receive(:upload)

      PublishServicesMetadataEvent.create(event_id: 0, environment: S3::ENVIRONMENT::INTEGRATION)
    end

    it 'when environment is set to production on component' do
      expect(
        SelfService.service(:storage_client)
      ).to receive(:upload)
      expect(
        SelfService.service(:integration_storage_client)
      ).not_to receive(:upload)

      PublishServicesMetadataEvent.create(event_id: 0, environment: S3::ENVIRONMENT::PRODUCTION)
    end
  end
end
