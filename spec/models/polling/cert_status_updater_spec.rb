require 'rails_helper'
require 'polling/cert_status_updater'

RSpec.describe CertStatusUpdater, type: :model do

  let(:root) { PKI.new }
  let(:hub_config_api) { HubConfigApi.new }
  let(:cert_status_updater) { CertStatusUpdater.new }
  let(:msa_enc_cert_1) { create(:msa_encryption_certificate, in_use_at: nil) }
  let(:msa_enc_cert_2) { create(:msa_encryption_certificate, in_use_at: nil) }
  let(:msa_sgn_cert_1) { create(:msa_signing_certificate, in_use_at: nil) }
  let(:msa_sgn_cert_2) { create(:msa_signing_certificate, in_use_at: nil) }
  let(:msa_sgn_cert_3) { create(:msa_signing_certificate, in_use_at: nil) }
  let(:service_1) { create(:service, entity_id: 'entity 1') }
  let(:service_2) { create(:service, entity_id: 'entity 2') }
  let(:service_3) { create(:service, entity_id: 'entity 3') }
  let(:sp_component_1) { create(:sp_component, services: [service_1]) }
  let(:sp_component_123) { create(:sp_component, services: [service_1, service_2, service_3]) }
  let(:sp_component_0) { create(:sp_component, services: []) }
  let(:sp_enc_cert_for_single_entity) { create(:sp_encryption_certificate, component: sp_component_1, in_use_at: nil) }
  let(:sp_enc_cert_for_multiple_entities) { create(:sp_encryption_certificate, component: sp_component_123, in_use_at: nil) }
  let(:sp_enc_cert_without_service) { create(:sp_encryption_certificate, component: sp_component_0, in_use_at: nil) }
  let(:sp_sgn_cert_for_single_entity) { create(:sp_signing_certificate, component: sp_component_1, in_use_at: nil) }
  let(:sp_sgn_cert_for_multiple_entities) { create(:sp_signing_certificate, component: sp_component_123, in_use_at: nil) }
  let(:sp_sgn_cert_other) { create(:sp_signing_certificate, in_use_at: nil) }

  describe '#update_hub_usage_status_for_cert' do
    context 'When given an encryption cert belonging to an MSA component' do
      it "leaves the cert unchanged if a call to the Hub does not show it is in use" do
        allow(hub_config_api).to receive(:encryption_certificate).and_return(msa_enc_cert_2.value)

        expect(msa_enc_cert_1.in_use_at).to be(nil)
        cert_status_updater.update_hub_usage_status_for_cert(hub_config_api, msa_enc_cert_1)
        expect(msa_enc_cert_1.in_use_at).to be(nil)
      end

      it "updates the cert's timestamp if a call to the Hub shows it is in use" do
        allow(hub_config_api).to receive(:encryption_certificate).and_return(msa_enc_cert_1.value)

        expect(msa_enc_cert_1.in_use_at).to be(nil)
        cert_status_updater.update_hub_usage_status_for_cert(hub_config_api, msa_enc_cert_1)
        expect(msa_enc_cert_1.in_use_at).not_to be(nil)
      end
    end

    context 'When given a signing cert belonging to an MSA component' do
      it "leaves the cert unchanged if a call to the Hub does not show it is in use" do
        allow(hub_config_api).to receive(:signing_certificates).and_return([msa_sgn_cert_2.value, msa_sgn_cert_3.value])

        expect(msa_sgn_cert_1.in_use_at).to be(nil)
        cert_status_updater.update_hub_usage_status_for_cert(hub_config_api, msa_sgn_cert_1)
        expect(msa_sgn_cert_1.in_use_at).to be(nil)
      end

      it "updates the cert's timestamp if a call to the Hub shows it is in use" do
        allow(hub_config_api).to receive(:signing_certificates).and_return([msa_sgn_cert_1.value, msa_sgn_cert_2.value])

        expect(msa_sgn_cert_1.in_use_at).to be(nil)
        cert_status_updater.update_hub_usage_status_for_cert(hub_config_api, msa_sgn_cert_1)
        expect(msa_sgn_cert_1.in_use_at).not_to be(nil)
      end
    end

    context 'When given an encryption cert belonging to an SP component' do
      it "leaves the cert unchanged if a call to the Hub does not show it is in use for all relevant entity IDs" do
        allow(hub_config_api).to receive(:encryption_certificate).with(sp_enc_cert_for_multiple_entities.component.environment, service_1.entity_id).and_return(sp_enc_cert_for_multiple_entities.value)
        allow(hub_config_api).to receive(:encryption_certificate).with(sp_enc_cert_for_multiple_entities.component.environment, service_2.entity_id).and_return(sp_enc_cert_for_single_entity.value)
        allow(hub_config_api).to receive(:encryption_certificate).with(sp_enc_cert_for_multiple_entities.component.environment, service_3.entity_id).and_return(sp_enc_cert_for_multiple_entities.value)

        expect(sp_enc_cert_for_multiple_entities.in_use_at).to be(nil)
        cert_status_updater.update_hub_usage_status_for_cert(hub_config_api, sp_enc_cert_for_multiple_entities)
        expect(sp_enc_cert_for_multiple_entities.in_use_at).to be(nil)
      end

      it "updates the cert's timestamp if a call to the Hub shows it is in use for all relevant entity IDs" do
        allow(hub_config_api).to receive(:encryption_certificate).with(sp_enc_cert_for_multiple_entities.component.environment, service_1.entity_id).and_return(sp_enc_cert_for_multiple_entities.value)
        allow(hub_config_api).to receive(:encryption_certificate).with(sp_enc_cert_for_multiple_entities.component.environment, service_2.entity_id).and_return(sp_enc_cert_for_multiple_entities.value)
        allow(hub_config_api).to receive(:encryption_certificate).with(sp_enc_cert_for_multiple_entities.component.environment, service_3.entity_id).and_return(sp_enc_cert_for_multiple_entities.value)

        expect(sp_enc_cert_for_multiple_entities.in_use_at).to be(nil)
        cert_status_updater.update_hub_usage_status_for_cert(hub_config_api, sp_enc_cert_for_multiple_entities)
        expect(sp_enc_cert_for_multiple_entities.in_use_at).not_to be(nil)
      end
    end

    context 'When given a signing cert belonging to an SP component' do
      it "leaves the cert unchanged if a call to the Hub does not show it is in use for all relevant entity IDs" do
        allow(hub_config_api).to receive(:signing_certificates).with(sp_sgn_cert_for_multiple_entities.component.environment, service_1.entity_id).and_return(sp_sgn_cert_for_multiple_entities.value, sp_sgn_cert_other.value)
        allow(hub_config_api).to receive(:signing_certificates).with(sp_sgn_cert_for_multiple_entities.component.environment, service_2.entity_id).and_return(sp_sgn_cert_for_single_entity.value, sp_sgn_cert_other.value)
        allow(hub_config_api).to receive(:signing_certificates).with(sp_sgn_cert_for_multiple_entities.component.environment, service_3.entity_id).and_return(sp_sgn_cert_for_multiple_entities.value)

        expect(sp_sgn_cert_for_multiple_entities.in_use_at).to be(nil)
        cert_status_updater.update_hub_usage_status_for_cert(hub_config_api, sp_sgn_cert_for_multiple_entities)
        expect(sp_sgn_cert_for_multiple_entities.in_use_at).to be(nil)
      end

      it "updates the cert's timestamp if a call to the Hub shows it is in use for all relevant entity IDs" do
        allow(hub_config_api).to receive(:signing_certificates).with(sp_sgn_cert_for_multiple_entities.component.environment, service_1.entity_id).and_return(sp_sgn_cert_for_multiple_entities.value, sp_sgn_cert_other.value)
        allow(hub_config_api).to receive(:signing_certificates).with(sp_sgn_cert_for_multiple_entities.component.environment, service_2.entity_id).and_return(sp_sgn_cert_for_multiple_entities.value, sp_sgn_cert_other.value)
        allow(hub_config_api).to receive(:signing_certificates).with(sp_sgn_cert_for_multiple_entities.component.environment, service_3.entity_id).and_return(sp_sgn_cert_for_multiple_entities.value)

        expect(sp_sgn_cert_for_multiple_entities.in_use_at).to be(nil)
        cert_status_updater.update_hub_usage_status_for_cert(hub_config_api, sp_sgn_cert_for_multiple_entities)
        expect(sp_sgn_cert_for_multiple_entities.in_use_at).not_to be(nil)
      end
    end

    context 'when given a cert belonging to an SP component with no services' do
      it "performs no action" do

        expect(sp_enc_cert_without_service.in_use_at).to be(nil)
        cert_status_updater.update_hub_usage_status_for_cert(hub_config_api, sp_enc_cert_without_service)
        expect(sp_enc_cert_without_service.in_use_at).to be(nil)
      end
    end
  end
end
