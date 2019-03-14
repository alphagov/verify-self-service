class NewComponentEvent < Event
    belongs_to_aggregate :component
    data_attributes :name, :component_type
  
    def build_component
      Component.new
    end
  
    def attributes_to_apply
      {name: self.name, component_type: self.component_type, created_at: self.created_at}
    end
end
