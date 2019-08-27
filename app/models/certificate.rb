class Certificate < Aggregate
  include CertificateConcern
  validates_inclusion_of :usage, in: %w[signing encryption]
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

  def not_after_nice_date_format
    x509.not_after.strftime("%d %B %Y, %H:%M%P")
  end

  def not_before_nice_date_format
    x509.not_before.strftime("%d %B %Y, %H:%M%P")
  end
end
