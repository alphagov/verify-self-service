class MsaComponent < Component
  has_many :certificates, as: :component
  has_many :services, dependent: :nullify

private

  def additional_metadata
    { entity_id: entity_id }
  end
end
