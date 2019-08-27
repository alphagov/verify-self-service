require 'yaml'
require 'rails_helper'

RSpec.describe PublishServicesMetadataEvent, type: :model do
  let(:published_at) { Time.now }
  let(:event_id) { 0 }
  let(:component) { MsaComponent.create(name: 'lala', entity_id: 'https//test-entity') }
  let(:event) { PublishServicesMetadataEvent.create(event_id: event_id, environment: 'test') }

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
  end

  context 'upload' do
    it 'when environment is set to integration on component' do
      expect(
        SelfService.service(:storage_client)
      ).to receive(:put_object).with(hash_including(bucket: "integration-bucket"))

      PublishServicesMetadataEvent.create(event_id: 0, environment: 'integration')
    end

    it 'when environment is set to production on component' do
      expect(
        SelfService.service(:storage_client)
      ).to receive(:put_object).with(hash_including(bucket: "production-bucket"))

      PublishServicesMetadataEvent.create(event_id: 0, environment: 'production')
    end
  end
end
