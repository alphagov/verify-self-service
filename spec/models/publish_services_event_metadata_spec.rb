require 'yaml'
require 'rails_helper'

RSpec.describe PublishServicesMetadataEvent, type: :model do
  include StorageSupport, NotifySupport

  Time.zone = 'London'

  let(:published_at) { Time.now }
  let(:event_id) { 0 }
  let(:component) { MsaComponent.create(name: 'lala', entity_id: 'https//test-entity') }
  let(:event) { PublishServicesMetadataEvent.create(event_id: event_id, environment: 'test') }
  let(:current) { Time.current }
  let(:in_hours) { travel_to Time.zone.local(current.year, current.month, current.day, 12, 00, 00)}

  context '#create' do
    before(:each) { in_hours }
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

  context 'upload when in hours' do
    before(:each) { in_hours }
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

    it 'does not persist event if publishing to s3 fails' do
      stub_storage_client_service_error

      event = PublishServicesMetadataEvent.create(event_id: event_id, environment: 'staging')
      expect(event).not_to be_persisted
    end
  end

  context 'upload when out of hours' do
    let(:team) { create(:team) }
    let(:login_current_user) {
      user = User.new
      user.user_id = SecureRandom.uuid
      user.team = team.id
      user.first_name = "Test"
      user.last_name = "Tester"
      user.email = "test@test.test"
      RequestStore.store[:user] = user
    }
    let(:event) { create(:upload_certificate_event) }
    let(:expected_body) {
      {
        email_address: 'idasupport@digital.cabinet-office.gov.uk',
        template_id: '0cab7f14-c616-4541-8a73-55bf26b93479',
        personalisation: {
          event_type: event.type,
          user_name: login_current_user.full_name,
          user_email: login_current_user.email,
          user_team: team.name,
        }
      }
    }
    before(:each) do
      login_current_user
      travel_to Time.zone.local(current.year, current.month, current.day, 22, 00, 00)
    end

    it 'sends notification when environment is set to production on component' do
      stub_notify_response
      PublishServicesMetadataEvent.create(event_id: event.id, environment: 'production')
      expect(stub_notify_request(expected_body)).to have_been_made.once
    end

    it 'does not send notification when environment is set to integration on component' do
      PublishServicesMetadataEvent.create(event_id: event.id, environment: 'integration')
      expect(stub_notify_request(expected_body)).not_to have_been_made
    end

    it 'does not send notification when time is 17:59:30' do
      travel_to Time.zone.local(current.year, current.month, current.day, 17, 59, 30)
      PublishServicesMetadataEvent.create(event_id: event.id, environment: 'production')
      expect(stub_notify_request(expected_body)).not_to have_been_made
    end

    it 'sends notification when time is 18:00:00' do
      travel_to Time.zone.local(current.year, current.month, current.day, 18, 00, 00)
      stub_notify_response
      PublishServicesMetadataEvent.create(event_id: event.id, environment: 'production')
      expect(stub_notify_request(expected_body)).to have_been_made.once
    end

    it 'sends notification when time is 7:59:30' do
      travel_to Time.zone.local(current.year, current.month, current.day, 7, 59, 30)
      stub_notify_response
      PublishServicesMetadataEvent.create(event_id: event.id, environment: 'production')
      expect(stub_notify_request(expected_body)).to have_been_made.once
    end

    it 'does not send notification when time is 8:00' do
      travel_to Time.zone.local(current.year, current.month, current.day, 8, 00, 00)
      PublishServicesMetadataEvent.create(event_id: event.id, environment: 'production')
      expect(stub_notify_request(expected_body)).not_to have_been_made
    end
  end
end
