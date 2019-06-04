class AddSpAndMsaComponentTables < ActiveRecord::Migration[5.2]
  def change
    create_table :sp_components do |t|
      t.string "name"
      t.string "component_type"
      t.integer "encryption_certificate_id"

      t.timestamps
    end

    create_table :msa_components do |t|
      t.string "name"
      t.string "component_type"
      t.integer "encryption_certificate_id"
      t.string "entity_id"

      t.timestamps
    end
  end
end
