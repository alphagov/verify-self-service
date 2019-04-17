require 'rails_helper'

RSpec.describe PublishServicesMetadataEvent, type: :model do
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

    it 'when event_id is blank publishServicesMetadataEvent is invalid' do
      invalid_event = PublishServicesMetadataEvent.create
      expect(invalid_event).to_not be_valid
      expect(invalid_event.data).to be_empty
    end

    it 'can attach config metadata' do
      event.upload
      expect(event.document.attached?).to be true
      expect(ActiveStorage::Blob.service.exist?(event.document.key)).to be true
    end

    it 'generates a link to uploaded config metadata' do
      event.upload
      current_url_helper = Rails.application.routes.url_helpers
      url = current_url_helper.rails_blob_path(event.document, only_path: true)
      expect(url).to end_with('servicesmetadata.json')
    end
  end
end
