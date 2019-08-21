module UserJourneyHelper
  def display_component(certificate)
    certificate.component_type == COMPONENT_TYPE::MSA ? COMPONENT_TYPE::MSA_SHORT : COMPONENT_TYPE::VSP_SHORT
  end
end
