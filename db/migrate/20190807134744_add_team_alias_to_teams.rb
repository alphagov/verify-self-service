class AddTeamAliasToTeams < ActiveRecord::Migration[5.2]
  def change
    add_column :teams, :team_alias, :string
  end
end
