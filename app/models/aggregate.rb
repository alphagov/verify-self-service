class Aggregate < ApplicationRecord
  self.abstract_class = true
  has_many :events
end
