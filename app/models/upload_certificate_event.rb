class UploadCertificateEvent < AggregatedEvent
  include Componerator

  belongs_to_aggregate :certificate
  data_attributes :value, :usage, :component_id, :component_type
  belongs_to :component, polymorphic: true
  before_save -> { convert_value_to_inline_der }
  after_save TriggerMetadataEventCallback.publish

  value_is_present :value
  certificate_is_new :value
  certificate_is_valid :value

  component_is_persisted :component

  validates_inclusion_of :usage, in: [CONSTANTS::SIGNING, CONSTANTS::ENCRYPTION]

  def build_certificate
    Certificate.new
  end

  def attributes_to_apply
    {
      usage: self.usage,
      value: self.value,
      component_id: self.component_id,
      component_type: self.component_type,
      created_at: self.created_at
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
end
