class CertStatusUpdater
  def initialize(hub_config_api)
    @hub_config_api = hub_config_api
  end

  def update_hub_usage_status_for_cert(certificate_to_check)
    outcomes = entity_ids_for(certificate_to_check).map { |entity_id| cert_is_in_use_for_entity_id?(entity_id, certificate_to_check) }

    if outcomes.all?
      update_cert_status_for(certificate_to_check)
    end
  end

private

  def entity_ids_for(certificate)
    if certificate.component.type == COMPONENT_TYPE::MSA_SHORT
      [certificate.component.entity_id]
    else
      certificate.component.services.map(&:entity_id)
    end
  end

  def cert_is_in_use_for_entity_id?(entity_id, certificate_to_check)
    certs_in_use = get_certs_from_hub(entity_id, certificate_to_check.encryption?)
    certs_in_use.include?(certificate_to_check.value)
  end

  def get_certs_from_hub(entity_id, is_for_encryption)
    if is_for_encryption
      Array.wrap(@hub_config_api.encryption_certificate(entity_id))
    else
      Array.wrap(@hub_config_api.signing_certificates(entity_id))
    end
  end

  def update_cert_status_for(certificate_to_check)
    time_cache_will_have_cleared_by = Time.now + Rails.configuration.hub_certs_cache_expiry
    CertificateInUseEvent.create(certificate: certificate_to_check, in_use_at: time_cache_will_have_cleared_by)
  end
end
