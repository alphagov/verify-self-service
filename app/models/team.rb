class Team < Aggregate
  has_many :components
  validates_uniqueness_of :name
end
