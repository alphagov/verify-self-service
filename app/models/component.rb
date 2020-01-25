class Component < Aggregate
  NON_SORTING_SEED = 999
  self.abstract_class = true

  has_many :signing_certificates,
           -> {
             where(usage: CERTIFICATE_USAGE::SIGNING)
           }, class_name: 'Certificate', as: :component
  has_many :encryption_certificates,
           -> {
             where(usage: CERTIFICATE_USAGE::ENCRYPTION).order(created_at: :desc)
           }, class_name: 'Certificate', as: :component
  has_many :enabled_signing_certificates,
           -> {
             where(usage: CERTIFICATE_USAGE::SIGNING, enabled: true).order(created_at: :desc)
           }, class_name: 'Certificate', as: :component
  has_many :disabled_signing_certificates,
           -> {
             where(usage: CERTIFICATE_USAGE::SIGNING, enabled: false)
           }, class_name: 'Certificate', as: :component

  belongs_to :encryption_certificate,
             -> { where(usage: CERTIFICATE_USAGE::ENCRYPTION) }, class_name: 'Certificate', optional: true

  belongs_to :team

  scope :for_user, ->(user) { where(team_id: user.team) }

  def self.all_pollable_certificates(environment)
    msa_certificates = MsaComponent.all_components_for_metadata(environment).map(&:unexpired_certificates_not_in_use)
    sp_certificates = SpComponent.all_components_for_metadata(environment).where.not(services: { id: nil }).map(&:unexpired_certificates_not_in_use)
    (msa_certificates + sp_certificates).flatten
  end

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

  def current_certificates
    certs = enabled_signing_certificates.map(&:clone)
    certs << encryption_certificate unless encryption_certificate.nil?
    certs
  end

  def unexpired_certificates_not_in_use
    current_certificates.reject { |c| c.expired? || c.in_use_at.present? }
  end

  def days_left
    sorted_certificates&.first&.days_left || NON_SORTING_SEED
  end

  def sorted_certificates
    current_certificates.sort_by { |c| c.expires_soon? ? c.days_left : NON_SORTING_SEED }
  end

  def previous_encryption_certificates
    encryption_certificates.where.not(id: encryption_certificate&.id)
  end

  def to_metadata
    {
      name: name,
      encryption_certificate: encryption_certificate&.to_metadata,
      signing_certificates: enabled_signing_certificates.map(&:to_metadata),
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

  def display_long_name
    I18n.t("user_journey.component_long_name.#{type}")
  end

  def active_cert?(certificate)
    current_certificates.include?(certificate)
  end
end
