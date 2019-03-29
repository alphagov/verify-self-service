class ServicesMetadata

  def self.to_json
    container = {}
    container[:publish_date] = Time.now

    Component.all.each do |component|
      case component.component_type
      when 'MSA'
        container.merge!(matching_service_adapters: build_component(component) || [])
      when 'SP', 'VSP'
        container.merge!(service_providers: build_component(component) || {})
      end
    end

  end

private

  def self.build_component(component)
    encryption = self.get_certificate(component, "encryption")
    signing = self.get_certificate(component, "signing")
    {name: component.name, encryption_certificate: encryption, signing_certificate: signing}
  end

  def self.get_certificate(component, usage)
    component.certificates.where(usage: usage).map do |cert|
      { name: certificate_subject(cert.value), value: cert.value }
    end
  end

  def self.create_certificate(value)
    begin
      OpenSSL::X509::Certificate.new(value)
    rescue
      OpenSSL::X509::Certificate.new(Base64.decode64(value))
    end
  end

  def self.certificate_subject(value)
    self.create_certificate(value).subject.to_s
  end
end
