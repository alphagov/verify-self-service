class CertStatusUpdater
  def update_hub_usage_status_for_cert(hub_config_api, certificate_to_check)
    outcomes = entity_ids_for(certificate_to_check).map { |entity_id| cert_is_in_use_for_entity_id?(hub_config_api, entity_id, certificate_to_check) }

    if outcomes.present? && outcomes.all?
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

  def cert_is_in_use_for_entity_id?(hub_config_api, entity_id, certificate_to_check)
    certs_in_use = get_certs_from_hub(hub_config_api, entity_id, certificate_to_check)
    certs_in_use.include?(certificate_to_check.value)
  end

  def get_certs_from_hub(hub_config_api, entity_id, certificate)
    if certificate.encryption?
      Array.wrap(hub_config_api.encryption_certificate(certificate.component.environment, entity_id))
    else
      Array.wrap(hub_config_api.signing_certificates(certificate.component.environment, entity_id))
    end
  end

  def update_cert_status_for(certificate_to_check)
    time_cache_will_have_cleared_by = Time.now + Rails.configuration.hub_certs_cache_expiry
    CertificateInUseEvent.create(certificate: certificate_to_check, in_use_at: time_cache_will_have_cleared_by)
  end
end
