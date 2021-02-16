class AddColumnTeamTypeWithValues < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :team_type, :string, default: 'rp'
  end
end
