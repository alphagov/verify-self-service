class NewTeamEvent < AggregatedEvent
  belongs_to_aggregate :team
  data_attributes :name

  validate :name_is_present

  def build_team
    Team.new
  end

  def attributes_to_apply
    { name: name, created_at: created_at }
  end
end
