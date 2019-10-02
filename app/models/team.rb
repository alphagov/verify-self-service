class Team < Aggregate
  has_many :components
  validates_uniqueness_of :name, message: I18n.t("team.errors.name_not_unique")
end
