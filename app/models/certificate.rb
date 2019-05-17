class Certificate < Aggregate
  validates_inclusion_of :usage, in: %w[signing encryption]
  validates_presence_of :usage, :value, :component_id
  belongs_to :component

  def to_subject
    certificate_subject
  end

  def to_metadata
    { name: to_subject, value: self.value }
  end

  def encryption?
    usage == CONSTANTS::ENCRYPTION
  end

  def signing?
    usage == CONSTANTS::SIGNING
  end
end
