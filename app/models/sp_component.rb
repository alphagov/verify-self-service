class SpComponent < Component
  has_many :certificates, as: :component
  has_many :services

  def view_component_type(vsp)
    vsp ? CONSTANTS::VSP_SHORT : CONSTANTS::SP_SHORT
  end

private

  def additional_metadata
    { id: id }
  end
end
