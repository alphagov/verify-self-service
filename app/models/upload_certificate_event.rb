class UploadCertificateEvent < AggregatedEvent
  include ComponentConcern
  include CertificateConcern

  belongs_to_aggregate :certificate
  data_attributes :value, :usage, :component_id, :component_type, :admin_upload
  belongs_to :component, polymorphic: true
  before_save { |event| event.value = convert_to_inline_der(value) }
  after_save TriggerMetadataEventCallback.publish

  validates :value, presence: true, certificate: true
  validate :certificate_is_new, on: :create
  validate :component_is_persisted
  validate :upload_max_2_signing_certificates, on: :create

  validates_inclusion_of :usage, in: [CERTIFICATE_USAGE::SIGNING, CERTIFICATE_USAGE::ENCRYPTION]

  def build_certificate
    Certificate.new
  end

  def attributes_to_apply
    {
      usage: usage,
      value: value,
      component_id: component_id,
      component_type: component_type,
      created_at: created_at,
    }
  end

  def component
    if @component.present?
      @component
    elsif component_id.present? && component_type.present?
      @component = klass_component(component_type).find_by_id(component_id)
    end
  end

  def component=(component)
    self.component_id = component.id
    self.component_type = component.component_type
    @component = component
  end

private

  def convert_to_inline_der(value)
    Base64.strict_encode64(to_x509(value).to_der)
  end

  def certificate_is_new
    errors.add(:certificate, I18n.t('components.errors.already_exists')) if certificate.persisted?
  end

  def component_is_persisted
    errors.add(:component, I18n.t('components.errors.must_exist')) unless component&.persisted?
  end

  def upload_max_2_signing_certificates
    return if usage == CERTIFICATE_USAGE::ENCRYPTION
    return if component.enabled_signing_certificates.count < 2

    errors.add(:certificate, I18n.t('certificates.errors.cannot_publish'))
  end
end
