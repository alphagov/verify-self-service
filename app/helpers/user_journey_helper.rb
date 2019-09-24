module UserJourneyHelper
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
    elsif certificate.component.enabled_signing_certificates.length == 2 && primary_signing_certificate?(certificate)
      "DEPLOYING"
    else
      "IN USE"
    end
  end

  def certificate_expiry_count(msa_components, sp_components)
    (msa_components + sp_components).map(&:certificates).flatten.select(&:expires_soon?).count
  end

  def display_component(component)
    if component.component_type == COMPONENT_TYPE::MSA
      COMPONENT_TYPE::MSA_SHORT
    elsif component.vsp
      COMPONENT_TYPE::VSP_SHORT
    else
      'service provider'
    end
  end
end
