class NewComponentEvent < Event
    belongs_to_aggregate :component
    data_attributes :name, :component_type

    validate :name_is_present
    validates_inclusion_of :component_type, in: ['VSP', 'MSA']
  
    def build_component
      Component.new
    end
  
    def attributes_to_apply
      {name: self.name, component_type: self.component_type, created_at: self.created_at}
    end

    private

    def name_is_present
      if !name_present?
        self.errors.add(:name, "can't be blank")
      end
    end
  
    def name_present?
      self.name.present?
    end
end
