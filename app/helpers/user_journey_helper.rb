module UserJourneyHelper
  def display_component(certificate)
    certificate.component_type == COMPONENT_TYPE::MSA ? COMPONENT_TYPE::MSA_SHORT : COMPONENT_TYPE::VSP_SHORT
  end

  def primary_signing_certificate(certificate)
    certificate == certificate.component.signing_certificates.reverse.first
  end

  def secondary_signing_certificate(certificate)
    certificate == certificate.component.signing_certificates.reverse.second
  end

  def position(certificate)
    certificate == certificate.component.signing_certificates.reverse.first ? 'primary' : 'secondary'
  end
end
