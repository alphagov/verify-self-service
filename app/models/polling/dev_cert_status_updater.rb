class DevCertStatusUpdater
  def update_hub_usage_status_for_cert(_hub_config_api, certificate)
    CertificateInUseEvent.create(certificate: certificate)
  end
end
