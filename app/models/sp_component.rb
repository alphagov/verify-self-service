class SpComponent < Component
  has_many :certificates, as: :component
  include ComponentConcern
end
