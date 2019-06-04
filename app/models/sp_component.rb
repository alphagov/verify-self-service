class SpComponent < Component
  has_many :certificates, as: :component
end
