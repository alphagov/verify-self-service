class Component < Aggregate
  self.abstract_class = true

  has_many :signing_certificates,
           -> {
             where(usage: CERTIFICATE_USAGE::SIGNING)
           }, class_name: 'Certificate', as: :component
  has_many :encryption_certificates,
           -> {
             where(usage: CERTIFICATE_USAGE::ENCRYPTION).order(created_at: 'desc')
           }, class_name: 'Certificate', as: :component
  has_many :enabled_signing_certificates,
           -> {
             where(usage: CERTIFICATE_USAGE::SIGNING, enabled: true).order(created_at: 'desc')
           }, class_name: 'Certificate', as: :component
  has_many :disabled_signing_certificates,
           -> {
             where(usage: CERTIFICATE_USAGE::SIGNING, enabled: false)
           }, class_name: 'Certificate', as: :component

  belongs_to :encryption_certificate,
             -> { where(usage: CERTIFICATE_USAGE::ENCRYPTION) }, class_name: 'Certificate', optional: true

  belongs_to :team

  def self.to_service_metadata(event_id, environment, published_at = Time.now)
    service_providers = SpComponent.all_components_for_metadata(environment)
    {
      published_at: published_at,
      event_id: event_id,
      connected_services: service_providers.map(&:services_to_metadata).flatten,
      matching_service_adapters: MsaComponent.all_components_for_metadata(environment).map(&:to_metadata),
      service_providers: service_providers.map(&:to_metadata),
    }
  end

  def self.all_components_for_metadata(environment)
    self.where(environment: environment)
        .includes(:services)
        .includes(:enabled_signing_certificates)
        .includes(:encryption_certificate)
  end

  def services_to_metadata
    services.map do |service|
      {
        entity_id: service.entity_id,
        service_provider_id: service.sp_component_id,
      }
    end
  end

  def previous_encryption_certificates
    encryption_certificates.where.not(id: encryption_certificate&.id)
  end

  def to_metadata
    {
      name: name,
      encryption_certificate: unexpired_encryption_certificate&.to_metadata,
      signing_certificates: unexpired_enabled_signing_certificates.map(&:to_metadata),
    }.merge(additional_metadata)
  end

  def type
    if component_type == COMPONENT_TYPE::MSA
      COMPONENT_TYPE::MSA_SHORT
    elsif vsp
      COMPONENT_TYPE::VSP_SHORT
    else
      COMPONENT_TYPE::SP_SHORT
    end
  end

  def display
    I18n.t("user_journey.component_name.#{type}")
  end

private

  def unexpired_encryption_certificate
    if encryption_certificate&.expired?
      Rails.logger.error "When publishing the meta data the service '#{name}' has been identified as having an expired encryption certificate."
      return nil
    end
    encryption_certificate
  end

  def unexpired_enabled_signing_certificates
    valid_certs = enabled_signing_certificates.reject(&:expired?)
    if valid_certs.size < enabled_signing_certificates.size
      Rails.logger.error "When publishing the meta data the service '#{name}' has been identified as having expired signing certificate(s)."
    end
    valid_certs
  end
end
