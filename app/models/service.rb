class Service < Aggregate
  belongs_to :sp_component, optional: true
  belongs_to :msa_component, optional: true
  validates_uniqueness_of :entity_id
  scope :sp_available, -> { where(sp_component_id: [nil, '']) }
end
