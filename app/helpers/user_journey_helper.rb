module UserJourneyHelper
  def display_component(certificate)
    certificate.component_type == COMPONENT_TYPE::MSA ? COMPONENT_TYPE::MSA_SHORT : COMPONENT_TYPE::VSP_SHORT
  end

  def primary_signing_certificate?(certificate)
    certificate == certificate.component.enabled_signing_certificates.first
  end

  def secondary_signing_certificate?(certificate)
    certificate == certificate.component.enabled_signing_certificates.second
  end

  def position(certificate)
    primary_signing_certificate?(certificate) ? 'primary' : 'secondary'
  end

  def certificate_status(certificate)
    if certificate.nil?
      "MISSING"
    elsif certificate.expires_soon?
      "EXPIRES IN #{(certificate.x509.not_after.to_date - Time.now.to_date).to_i} DAYS"
    elsif certificate.component.signing_certificates.length == 2 && primary_signing_certificate?(certificate)
      "DEPLOYING"
    else
      "IN USE"
    end
  end
end
