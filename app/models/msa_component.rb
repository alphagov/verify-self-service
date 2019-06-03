class MsaComponent < Component
  has_many :certificates, as: :component
  has_many :services
end
