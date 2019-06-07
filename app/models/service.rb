class Service < Aggregate
  belongs_to :sp_component, optional: true
  belongs_to :msa_component, optional: true

  validates_presence_of :entity_id
end
