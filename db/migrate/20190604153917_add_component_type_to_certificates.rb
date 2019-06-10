class AddComponentTypeToCertificates < ActiveRecord::Migration[5.2]
  def change
    add_column :certificates, :component_type, :string
  end
end
