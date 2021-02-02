class NewServiceEvent < AggregatedEvent
  belongs_to_aggregate :service
  data_attributes :entity_id, :sp_component_id, :msa_component_id, :name
  validate :name_is_present
  validates_presence_of :entity_id, message: I18n.t('services.errors.missing_entity_id')
  validates :entity_id, format: { without: /\s/, message: I18n.t('services.errors.invalid_entity_id_format') }
  before_validation :strip_entity_id

  def build_service
    Service.new
  end

  def attributes_to_apply
    {
      entity_id: entity_id,
      sp_component_id: sp_component_id,
      msa_component_id: msa_component_id,
      name: name,
      created_at: created_at,
    }
  end
end
