class Component < Aggregate
  self.abstract_class = true

  has_many :signing_certificates,
           -> { where(usage: CONSTANTS::SIGNING) }, class_name: 'Certificate'
  has_many :encryption_certificates,
           -> {
             where(usage: CONSTANTS::ENCRYPTION).order(created_at: 'desc')
           }, class_name: 'Certificate'
  has_many :enabled_signing_certificates,
           -> { where(usage: CONSTANTS::SIGNING, enabled: true) }, class_name: 'Certificate'
  has_many :disabled_signing_certificates,
           -> { where(usage: CONSTANTS::SIGNING, enabled: false) }, class_name: 'Certificate'

  belongs_to :encryption_certificate,
             -> { where(usage: CONSTANTS::ENCRYPTION) }, class_name: 'Certificate', optional: true

  def self.to_service_metadata(event_id, published_at = Time.now)
    matching_service_adapters = MsaComponent.includes(:enabled_signing_certificates,
                                                      :encryption_certificate)
    service_providers = SpComponent.includes(:enabled_signing_certificates,
                                             :encryption_certificate)
    components = matching_service_adapters + service_providers

    {
      published_at: published_at,
      event_id: event_id,
      connected_services: components.map(&:services_to_metadata).flatten,
      matching_service_adapters: matching_service_adapters.map(&:to_metadata),
      service_providers: service_providers.map(&:to_metadata)
    }
  end

  def services_to_metadata
    services.map do |service|
      {
        entity_id: service.entity_id,
        service_provider_id: service.sp_component_id
      }
    end
  end

  def previous_encryption_certificates
    encryption_certificates.where.not(id: encryption_certificate&.id)
  end

  def to_metadata
    {
      name: name,
      encryption_certificate: encryption_certificate&.to_metadata,
      signing_certificates: enabled_signing_certificates.map(&:to_metadata)
    }.merge(additional_metadata)
  end
end
