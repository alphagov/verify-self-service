class MsaComponent < Component
  has_many :certificates, as: :component
end
