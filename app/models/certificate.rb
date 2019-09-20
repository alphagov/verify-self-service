class Certificate < Aggregate
  include CertificateConcern
  validates_inclusion_of :usage, in: [CERTIFICATE_USAGE::SIGNING, CERTIFICATE_USAGE::ENCRYPTION]
  validates_presence_of :usage, :value, :component
  belongs_to :component, polymorphic: true

  def to_metadata
    { name: x509.subject.to_s, value: self.value }
  end

  def encryption?
    usage == CERTIFICATE_USAGE::ENCRYPTION
  end

  def signing?
    usage == CERTIFICATE_USAGE::SIGNING
  end

  def x509
    to_x509(value)
  end

  def issuer_common_name
    x509.subject.to_a.find { |issuer, _, _| issuer == 'CN' }[1]
  end

  def expires_soon?
    x509.not_after - Time.now < 30.day
  end
end
