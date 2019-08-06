class ChangeComponentEvent < AggregatedEvent
  belongs_to_aggregate :component
  data_attributes :name, :entity_id, :team_id

  def attributes_to_apply
    changes = component
              .attributes
              .slice(component.changed.join(','))

    self.data = changes
    changes
  end
end
