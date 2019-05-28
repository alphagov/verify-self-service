class UploadCertificateEvent < AggregatedEvent
  belongs_to_aggregate :certificate
  data_attributes :value, :usage, :component_id
  before_save -> { convert_value_to_inline_der }
  after_save TriggerMetadataEventCallback.publish

  value_is_present :value
  certificate_is_new :value
  certificate_is_valid :value

  component_is_persisted :component_id

  validates_inclusion_of :usage, in: [CONSTANTS::SIGNING, CONSTANTS::ENCRYPTION]

  def build_certificate
    Certificate.new
  end

  def attributes_to_apply
    {
      usage: self.usage,
      value: self.value,
      component_id: self.component_id,
      created_at: self.created_at
    }
  end

  def component
    if @component&.id == self.component_id
      @component
    else
      @component = Component.find_by_id(self.component_id)
    end
  end

  def component=(component)
    self.component_id = component.id
    @component = component
  end
end
