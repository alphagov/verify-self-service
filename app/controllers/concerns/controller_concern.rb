module ControllerConcern
  extend ActiveSupport::Concern

  def component_key(params)
    params.keys.find { |m| m.include?('component_id') }
  end

  def component_name_from_params(params)
    key = component_key(params)
    key.gsub('_id', '').split('_').map(&:titleize).join
  end

  def certificate_issuer_common_name(certificate)
    certificate_issuer_find(certificate, "CN")
  end

  def certificate_issuer_find(certificate, name)
    certificate.x509.subject.to_a.find { |issuer, _, _| issuer == name }[1]
  end
end
