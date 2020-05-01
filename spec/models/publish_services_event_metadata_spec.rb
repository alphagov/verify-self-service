require 'yaml'
require 'rails_helper'
require 'polling/cert_status_updater'
require 'polling/scheduler'

RSpec.describe PublishServicesMetadataEvent, type: :model do
  include StorageSupport, StubHubConfigApiSupport, NotifySupport
  Time.zone = 'London'

  before(:each) do
    stub_const('CERT_STATUS_UPDATER', CertStatusUpdater.new)
    stub_const('SCHEDULER', Polling::Scheduler.new)
  end
  after(:each) do
    SCHEDULER.rufus_scheduler.shutdown(:kill)
  end
  let(:published_at) { Time.now }
  let(:event_id) { 0 }
  let(:component) { MsaComponent.create(name: 'lala', entity_id: 'https//test-entity') }
  let(:event) { PublishServicesMetadataEvent.create(event_id: event_id, environment: 'test') }
  let(:current) { Time.current }
  let(:in_hours) { travel_to Time.zone.local(current.year, current.month, current.day, 12, 00, 00)}
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
  context '#create' do
    before(:each) { in_hours }
    it 'creates a valid event which contains hard-coded data' do
      expect(event.data).to include(
        'event_id',
        'services_metadata',
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
        SelfService.service(:storage_client),
      ).to receive(:put_object).with(hash_including(bucket: "integration-bucket"))

      PublishServicesMetadataEvent.create(event_id: 0, environment: 'integration')
    end

    it 'when environment is set to production on component' do
      login_current_user
      expect(
        SelfService.service(:storage_client),
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
    let(:sp_signing_certificate) { create(:sp_signing_certificate) }
    let(:msa_encryption_certificate) { create(:msa_encryption_certificate) }
    let(:new_msa_encryption_certificate) { create(:msa_encryption_certificate) }
    let(:msa_signing_certificate) { create(:msa_signing_certificate) }
    after(:each) do
      SpComponent.destroy_all
      MsaComponent.destroy_all
    end

    context 'does not occur' do
      require 'polling/dev_cert_status_updater'
      it 'updates certificate in_use_at' do
        expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).to be_nil
        stub_const('CERT_STATUS_UPDATER', DevCertStatusUpdater.new)
        allow(CERT_STATUS_UPDATER).to receive(:update_hub_usage_status_for_cert).with(anything, sp_signing_certificate)
          .and_return(CertificateInUseEvent.create(certificate: sp_signing_certificate))

        create(:assign_sp_component_to_service_event, service: service, sp_component_id: sp_signing_certificate.component.id)
        expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).to be_present
      end
    end

    context 'occurs' do

      context 'due assign component to service event' do
        it 'called once and calls hub to update certificate in_use_at' do
          stub_signing_certificates_hub_request(
            environment: sp_signing_certificate.component.environment,
            entity_id: service.entity_id,
          )
            .to_return(body: hub_response_for_signing(entity_id: service.entity_id, value: sp_signing_certificate.value))

          expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).to be_nil

          create(:assign_sp_component_to_service_event, service: service, sp_component_id: sp_signing_certificate.component.id)
          expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).to be_present
        end

        it 'called once and calls hub exactly 3 times until certificate is in use' do
          stub_signing_certificates_hub_request(
            environment: sp_signing_certificate.component.environment,
            entity_id: service.entity_id,
          )
            .to_return(status: 404)
            .times(2).then
            .to_return(status: 200, body: hub_response_for_signing(entity_id: service.entity_id, value: sp_signing_certificate.value))

          expect(HUB_CONFIG_API).to receive(:signing_certificates).with(any_args).and_call_original.exactly(3).times

          expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).to be_nil

          create(:assign_sp_component_to_service_event, service: service, sp_component_id: sp_signing_certificate.component.id)

          wait_until { Certificate.find_by_id(sp_signing_certificate.id).in_use_at }
          expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).to be_present
        end

        it 'called many times and calls hub exactly 3 times until certificate is in use' do
          stub_signing_certificates_hub_request(
            environment: sp_signing_certificate.component.environment,
            entity_id: service.entity_id,
          )
            .to_return(status: 404)
            .times(2).then
            .to_return(status: 200, body: hub_response_for_signing(entity_id: service.entity_id, value: sp_signing_certificate.value))

          expect(HUB_CONFIG_API).to receive(:signing_certificates).with(any_args).and_call_original.exactly(3).times

          expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).to be_nil

          wait_until {
            create(:assign_sp_component_to_service_event, service: service, sp_component_id: sp_signing_certificate.component.id)
            Certificate.find_by_id(sp_signing_certificate.id).in_use_at
          }
          expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).to be_present
        end

        it 'called once and calls hub but certificate is never in use when response not successful' do
          stub_signing_certificates_hub_request(
            environment: sp_signing_certificate.component.environment,
            entity_id: service.entity_id,
          )
            .to_return(status: 404, body: "")
            .times(3)

          expect(Rails.logger).to receive(:error)
            .with("Error getting signing certificates for entity_id: #{service.entity_id}! (Code: 404)")
          expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).to be_nil
          create(:assign_sp_component_to_service_event, service: service, sp_component_id: sp_signing_certificate.component.id)
          expect(Certificate.find_by_id(sp_signing_certificate.id).in_use_at).to be_nil
        end
      end

      context 'due to replace encryption certificate event' do
        it 'called once and polls hub to update certificate in_use_at' do
          stub_encryption_certificate_hub_request(
            environment: new_msa_encryption_certificate.component.environment,
            entity_id: new_msa_encryption_certificate.component.entity_id,
          )
          .to_return(body: hub_response_for_encryption(entity_id: new_msa_encryption_certificate.component.entity_id, value: new_msa_encryption_certificate.value))

          expect(Certificate.find_by_id(new_msa_encryption_certificate.id).in_use_at).to be_nil

          create(:replace_encryption_certificate_event, encryption_certificate_id: new_msa_encryption_certificate.id, component: msa_encryption_certificate.component)
          expect(Certificate.find_by_id(new_msa_encryption_certificate.id).in_use_at).to be_present
        end

        it 'called once and polls hub exactly 3 times until certificate is in use' do
          stub_encryption_certificate_hub_request(
            environment: new_msa_encryption_certificate.component.environment,
            entity_id: new_msa_encryption_certificate.component.entity_id,
          )
            .to_return(status: 404)
            .times(2).then
            .to_return(status: 200, body: hub_response_for_encryption(entity_id: new_msa_encryption_certificate.component.entity_id, value: new_msa_encryption_certificate.value))

          expect(HUB_CONFIG_API).to receive(:encryption_certificate).with(any_args).and_call_original.exactly(3).times
          expect(Component).to receive(:all_pollable_certificates).and_call_original
            .with(msa_encryption_certificate.component.environment).once

          expect(Certificate.find_by_id(new_msa_encryption_certificate.id).in_use_at).to be_nil

          create(:replace_encryption_certificate_event, encryption_certificate_id: new_msa_encryption_certificate.id, component: msa_encryption_certificate.component)

          wait_until { Certificate.find_by_id(new_msa_encryption_certificate.id).in_use_at }
          expect(Certificate.find_by_id(new_msa_encryption_certificate.id).in_use_at).to be_present
        end

        it 'called many times and polls hub exactly 3 times until certificate is in use' do
          stub_encryption_certificate_hub_request(
            environment: new_msa_encryption_certificate.component.environment,
            entity_id: new_msa_encryption_certificate.component.entity_id,
          )
            .to_return(status: 404)
            .times(2).then
            .to_return(status: 200, body: hub_response_for_encryption(entity_id: new_msa_encryption_certificate.component.entity_id, value: new_msa_encryption_certificate.value))

          expect(HUB_CONFIG_API).to receive(:encryption_certificate).with(any_args).and_call_original.exactly(3).times

          expect(Certificate.find_by_id(new_msa_encryption_certificate.id).in_use_at).to be_nil

          wait_until {
            create(:replace_encryption_certificate_event, encryption_certificate_id: new_msa_encryption_certificate.id, component: msa_encryption_certificate.component)
            Certificate.find_by_id(new_msa_encryption_certificate.id).in_use_at
          }
          expect(Certificate.find_by_id(new_msa_encryption_certificate.id).in_use_at).to be_present
        end

        it 'called once and polls hub but certificate is never in use when response not successful' do
          stub_encryption_certificate_hub_request(
            environment: new_msa_encryption_certificate.component.environment,
            entity_id: new_msa_encryption_certificate.component.entity_id,
          )
            .to_return(status: 404)
            .times(3)

          expect(Rails.logger).to receive(:error)
            .with("Error getting encryption certificate for entity_id: #{new_msa_encryption_certificate.component.entity_id}! (Code: 404)")
          expect(Certificate.find_by_id(new_msa_encryption_certificate.id).in_use_at).to be_nil
          create(:replace_encryption_certificate_event, encryption_certificate_id: new_msa_encryption_certificate.id, component: msa_encryption_certificate.component)
          expect(Certificate.find_by_id(new_msa_encryption_certificate.id).in_use_at).to be_nil
        end
      end

      context 'due to upload certificate event' do
        it 'called once and polls hub to update certificate in_use_at' do
          stub_signing_certificates_hub_request(
            environment: msa_signing_certificate.component.environment,
            entity_id: msa_signing_certificate.component.entity_id,
          )
            .to_return(body: hub_response_for_signing(entity_id: msa_signing_certificate.component.entity_id, value: msa_signing_certificate.value))

          expect(Certificate.find_by_id(msa_signing_certificate.id).in_use_at).to be_nil

          create(:upload_certificate_event, component: msa_signing_certificate.component)
          expect(Certificate.find_by_id(msa_signing_certificate.id).in_use_at).to be_present
        end

        it 'called once and polls hub exactly 4 times until certificate is in use' do
          stub_signing_certificates_hub_request(
            environment: msa_signing_certificate.component.environment,
            entity_id: msa_signing_certificate.component.entity_id,
          )
            .to_return(status: 404)
            .times(2).then
            .to_return(status: 200, body: hub_response_for_signing(entity_id: msa_signing_certificate.component.entity_id, value: msa_signing_certificate.value))

          expect(HUB_CONFIG_API).to receive(:signing_certificates).with(any_args).and_call_original.exactly(4).times

          expect(Certificate.find_by_id(msa_signing_certificate.id).in_use_at).to be_nil
          create(:upload_certificate_event, component: msa_signing_certificate.component)
          wait_until { Certificate.find_by_id(msa_signing_certificate.id).in_use_at }
          expect(Certificate.find_by_id(msa_signing_certificate.id).in_use_at).to be_present
        end

        it 'called once and polls hub but certificate is never in use when response not successful' do
          stub_signing_certificates_hub_request(
            environment: msa_signing_certificate.component.environment,
            entity_id: msa_signing_certificate.component.entity_id,
          )
            .to_return(status: 404)
            .times(3)

          expect(Rails.logger).to receive(:error)
            .with("Error getting signing certificates for entity_id: #{new_msa_encryption_certificate.component.entity_id}! (Code: 404)")
            .twice
          expect(Certificate.find_by_id(msa_signing_certificate.id).in_use_at).to be_nil
          create(:upload_certificate_event, component: msa_signing_certificate.component)
          expect(Certificate.find_by_id(msa_signing_certificate.id).in_use_at).to be_nil
        end
      end
    end
  end
end
