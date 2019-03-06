class Certificate < Aggregate
  validates_inclusion_of :usage, in: ['signing', 'encryption']
  validates_presence_of :usage, :value
end
