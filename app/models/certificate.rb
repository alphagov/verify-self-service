class Certificate < Aggregate
  include Utilities::Certificate

  validates_inclusion_of :usage, in: %w[signing encryption]
  validates_presence_of :usage, :value, :component_id
  belongs_to :component

  def to_metadata
    subject = CertificateFactory.to_subject(value)
    { name: subject, value: self.value }
  end

  def encryption?
    usage == CONSTANTS::ENCRYPTION
  end

  def signing?
    usage == CONSTANTS::SIGNING
  end
end
