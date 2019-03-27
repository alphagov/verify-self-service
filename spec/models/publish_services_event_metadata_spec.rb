require 'rails_helper'

RSpec.describe PublishServicesMetadataEvent, type: :model do
  context '#create' do
    it 'creates an event which contains hard-coded data' do
      event = PublishServicesMetadataEvent.create(event_id: 3, cert_config: "I am here" )
      expect(event.data).to include("cert_config" => "I am here" )
    end
  end
end
