module UserJourneyHelper
  def primary_signing_certificate?(certificate)
    certificate == certificate.component.enabled_signing_certificates.first
  end

  def secondary_signing_certificate?(certificate)
    certificate == certificate.component.enabled_signing_certificates.second
  end

  def deployment_in_progress?(certificate)
    certificate.component.enabled_signing_certificates.first.deploying?
  end

  def position(certificate)
    primary_signing_certificate?(certificate) ? 'primary' : 'secondary'
  end

  def certificate_status(certificate)
    if certificate.nil?
      "MISSING"
    elsif certificate.expires_soon?
      "EXPIRES IN #{certificate.days_left} DAYS"
    elsif certificate.deploying?
      "DEPLOYING"
    else
      "IN USE"
    end
  end

  def certificate_expiry_count(components)
    components.map(&:current_certificates).flatten.select(&:expires_soon?).count
  end
end
