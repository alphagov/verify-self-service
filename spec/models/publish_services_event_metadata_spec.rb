require 'rails_helper'

RSpec.describe PublishServicesMetadataEvent, type: :model do
  context '#create' do
    it 'creates an event which contains hard-coded data' do
      event = PublishServicesMetadataEvent.create(event_id: 112, cert_config: ServicesMetadata.to_json(112))
      expect(event.data).to include("cert_config")
    end
  end
end
