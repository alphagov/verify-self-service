class ChangeAdminTeamTypeToOther < ActiveRecord::Migration[6.0]
  def change
    Team.where(name: "gds").find_each { |u| u.update(team_type: "other") }
  end
end
