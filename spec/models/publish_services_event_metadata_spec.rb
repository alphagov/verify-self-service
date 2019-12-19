require 'yaml'
require 'rails_helper'
require 'polling/cert_status_updater'

RSpec.describe PublishServicesMetadataEvent, type: :model do
  include StorageSupport, NotifySupport

  Time.zone = 'London'
  include StorageSupport, StubHubConfigApiSupport
  before(:each) do
    stub_const('CERT_STATUS_UPDATER', CertStatusUpdater.new)
  end

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
  
  context 'polling' do
    let!(:service) { create(:service) }
    let(:hub_response_for_signing_certificate) {
      [{
        issuerId: service.entity_id,
        certificate: sp_signing_certificate.value,
        keyUse: 'Signing',
        federationEntityType: 'RP',
      }].to_json
    }

    after(:each) do
      SpComponent.destroy_all
      MsaComponent.destroy_all
    end

    context 'does not occur' do
      require 'polling/dev_cert_status_updater'
      let(:sp_signing_certificate) { create(:sp_signing_certificate) }
      it 'updates certificate in_use_at' do
        expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).to be_nil
        stub_const('CERT_STATUS_UPDATER', DevCertStatusUpdater.new)
        expect_any_instance_of(Worker).to receive(:poll)
          .with(hash_including(environment: sp_signing_certificate.component.environment))
        allow(CERT_STATUS_UPDATER).to receive(:update_hub_usage_status_for_cert).with(anything, sp_signing_certificate)
          .and_return(CertificateInUseEvent.create(certificate: sp_signing_certificate))

        create(:assign_sp_component_to_service_event, service: service, sp_component_id: sp_signing_certificate.component.id)
        expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).not_to be_nil
      end
    end

    context 'occurs' do
      let(:msa_encryption_certificate) { create(:msa_encryption_certificate) }
      let(:sp_signing_certificate) { create(:sp_signing_certificate) }
      it 'updates certificate in_use_at' do
        stub_signing_certificates_hub_request(
          environment: sp_signing_certificate.component.environment,
          entity_id: service.entity_id
        )
        .to_return(body: hub_response_for_signing_certificate)

        expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).to be_nil

        create(:assign_sp_component_to_service_event, service: service, sp_component_id: sp_signing_certificate.component.id)
        expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).not_to be_nil
      end

      it 'polls until certificate is in use then updates in_use_at' do
        stub_signing_certificates_hub_request(
          environment: sp_signing_certificate.component.environment,
          entity_id: service.entity_id
        )
        .to_return(status: 404)
        .times(2).then
        .to_return(status: 200, body: hub_response_for_signing_certificate)

        expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).to be_nil

        create(:assign_sp_component_to_service_event, service: service, sp_component_id: sp_signing_certificate.component.id)

        loop { break if Certificate.find_by_id(sp_signing_certificate.id).in_use_at }
        expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).not_to be_nil
      end

      it 'polls but certificate is not in use' do
        stub_signing_certificates_hub_request(
          environment: sp_signing_certificate.component.environment,
          entity_id: service.entity_id
        )
        .to_return(status: 404)
        .times(2).then
        .to_return(status: 404)
        scheduler = Polling::Scheduler.new(overlap: false, timeout: '3.0s', times: 3)
        stub_const('CERT_STATUS_UPDATER', DevCertStatusUpdater.new)
        expect_any_instance_of(Worker).to receive(:poll)
          .with(hash_including(environment: sp_signing_certificate.component.environment))

        expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).to be_nil
        create(:assign_sp_component_to_service_event, service: service, sp_component_id: sp_signing_certificate.component.id)
        expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).to be_nil
      end
    end
  end
end
