class Component < Aggregate

  has_many :certificates
  has_many :signing_certificates,
           -> { where(usage: CONSTANTS::SIGNING) }, class_name: 'Certificate'
  has_many :enabled_signing_certificates,
           -> { where(usage: CONSTANTS::SIGNING, enabled: true) }, class_name: 'Certificate'
  has_many :disabled_signing_certificates,
           -> { where(usage: CONSTANTS::SIGNING, enabled: false) }, class_name: 'Certificate'

  belongs_to :encryption_certificate, -> { where(usage: CONSTANTS::ENCRYPTION) },
                                      class_name: 'Certificate', optional: true


  scope :matching_service_adapters, -> { where(component_type: 'MSA') }
  scope :service_providers,
        -> { where(component_type: 'VSP').or(where(component_type: 'SP')) }

  def self.to_service_metadata(event_id, published_at = Time.now)
    matching_service_adapters = Component.matching_service_adapters
                                         .includes(:enabled_signing_certificates,
                                                   :encryption_certificate)
    service_providers = Component.service_providers
                                 .includes(:enabled_signing_certificates,
                                           :encryption_certificate)
      { published_at: published_at, event_id: event_id,
        matching_service_adapters: matching_service_adapters.map(&:to_metadata),
        service_providers: service_providers.map(&:to_metadata) }
  end

  def to_metadata
    signing = self.enabled_signing_certificates.map(&:to_metadata)

    encryption = self.encryption_certificate&.to_metadata
    {
      name: self.name,
      encryption_certificate: encryption,
      signing_certificates: signing
    }
  end
end
