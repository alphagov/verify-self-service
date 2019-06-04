class Certificate < Aggregate
  validates_inclusion_of :usage, in: %w[signing encryption]
  validates_presence_of :usage, :value, :component_id, :component_type
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
    OpenSSL::X509::Certificate.new(value)
  rescue # rubocop:disable Style/RescueStandardError
    OpenSSL::X509::Certificate.new(Base64.decode64(value))
  end
end
