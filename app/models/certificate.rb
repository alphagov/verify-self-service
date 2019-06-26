class Certificate < Aggregate
  include CertificateConcern
  validates_inclusion_of :usage, in: %w[signing encryption]
  validates_presence_of :usage, :value, :component
  belongs_to :component, polymorphic: true

  def to_metadata
    { name: x509.subject.to_s, value: self.value }
  end

  def encryption?
    usage == CONSTANTS::ENCRYPTION
  end

  def signing?
    usage == CONSTANTS::SIGNING
  end

  def x509
    to_x509(value)
  end
end
