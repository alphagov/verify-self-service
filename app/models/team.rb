class Team < Aggregate
  has_many :components
  validates_uniqueness_of :name, message: I18n.t('team.errors.name_not_unique')
  validates_uniqueness_of :team_alias, message: I18n.t('team.errors.name_not_unique')

  scope :retrieve_teams_by_type, ->(team) { where(team_type: team) }
end
