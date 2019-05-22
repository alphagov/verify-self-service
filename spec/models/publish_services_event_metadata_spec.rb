require 'yaml'
require 'rails_helper'

RSpec.describe PublishServicesMetadataEvent, type: :model do
  include Utilities::Configuration::Settings

  let(:published_at) { Time.now }
  let(:event_id) { 0 }
  let(:component) { Component.create(name: 'lala', component_type: 'MSA') }
  let(:event) do
    PublishServicesMetadataEvent.create(event_id: event_id)
  end

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
      key = "verify_services_metadata.json"
      expected_chunks = event.metadata
      current_active_storage_env = Rails.configuration.active_storage.service

      service = ActiveStorage::Service.configure(
        current_active_storage_env,
        configuration('storage.yml')
      )

      actual_chunks = []
      service.download key do |chunk|
        actual_chunks << chunk
      end

      expect(expected_chunks.to_json).to eq(actual_chunks.first)
    end
  end
end
