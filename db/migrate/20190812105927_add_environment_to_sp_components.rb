class AddEnvironmentToSpComponents < ActiveRecord::Migration[5.2]
  def change
    add_column :sp_components, :environment, :string
    change_column :sp_components, :environment, :string, null: false, default: 'development'
  end
end
