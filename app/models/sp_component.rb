class SpComponent < Component
  has_many :certificates, as: :component
  has_many :services
  include ComponentConcern
end
