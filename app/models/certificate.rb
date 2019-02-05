class Certificate < ApplicationRecord
  validates_inclusion_of :usage, in: ['signing', 'encryption']
end
