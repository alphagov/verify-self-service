require 'utilities/certificate/certificate_factory'
class Certificate < Aggregate
  include Utilities::Certificate

  validates_inclusion_of :usage, in: %w[signing encryption]
  validates_presence_of :usage, :value, :component_id
  belongs_to :component

  def to_metadata
    certificate_factory = CertificateFactory.new(value)
    subject = certificate_factory.to_subject
    { name: subject, value: self.value }
  end
end
