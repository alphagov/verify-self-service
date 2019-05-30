class NewServiceEvent < AggregatedEvent
  belongs_to_aggregate :service
  data_attributes :entity_id, :component_id, :msa_component_id, :name

  def build_service
    Service.new
  end

  def attributes_to_apply
    {
      entity_id: entity_id,
      component_id: component_id,
      msa_component_id: msa_component_id,
      name: name,
      created_at: created_at
    }
  end
end
