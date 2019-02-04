class Certificate < ApplicationRecord
  validates_presence_of :usage
  validates_presence_of :value
end
