class AddEnvironmentToMsaComponents < ActiveRecord::Migration[5.2]
  def change
    add_column :msa_components, :environment, :string
    change_column :msa_components, :environment, :string, null: true
  end
end
