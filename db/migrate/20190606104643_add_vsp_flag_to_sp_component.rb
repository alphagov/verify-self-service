class AddVspFlagToSpComponent < ActiveRecord::Migration[5.2]
  def change
    add_column :sp_components, :vsp, :boolean, default: false
  end
end
