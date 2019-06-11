class CorrectServicesTableColumns < ActiveRecord::Migration[5.2]
  def change
    rename_column :services, :component_id, :sp_component_id
  end
end
