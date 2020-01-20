class DevCertStatusUpdater
  def update_hub_usage_status_for_cert(_hub_config_api, certificate)
    time_cache_will_have_cleared_by = Time.now + Rails.configuration.hub_certs_cache_expiry
    CertificateInUseEvent.create(certificate: certificate, in_use_at: time_cache_will_have_cleared_by)
  end
end
