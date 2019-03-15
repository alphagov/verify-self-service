class AddComponentIdToCertificates < ActiveRecord::Migration[5.2]
  def change
    add_column :certificates, :component_id, :integer
  end
end
