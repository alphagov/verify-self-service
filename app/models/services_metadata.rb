require 'json'
class ServicesMetadata

  def self.to_json(event_id, component = Component.all, publish_date = Time.now)
    config = {}
    config[:publish_date] = publish_date
    config[:event_id] = event_id
    config[:matching_service_adapters] = []
    config[:service_providers] = []
    populate_config(config, component).to_json
  end

  private_class_method def self.populate_config(config, component)
    component.each do |item|
      case item.component_type
      when 'MSA'
        config[:matching_service_adapters] << build_component(item)
      when 'SP', 'VSP'
        config[:service_providers] << build_component(item)
      end
    end
    config
  end

  private_class_method def self.build_component(item)
    encryption = get_certificate(item, 'encryption').first || {}
    signing = get_certificate(item, 'signing') || []
    {
      name: item.name,
      encryption_certificate: encryption,
      signing_certificates: signing
    }
  end

  private_class_method def self.get_certificate(item, usage)
    item.certificates.where(usage: usage).map do |cert|
      { name: certificate_subject(cert.value), value: cert.value }
    end
  end

  private_class_method def self.certificate_subject(value)
    OpenSSL::X509::Certificate.new(Base64.decode64(value)).subject.to_s
  end
end
