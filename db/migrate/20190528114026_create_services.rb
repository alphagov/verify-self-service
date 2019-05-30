class CreateServices < ActiveRecord::Migration[5.2]
  def change
    create_table :services do |t|
      t.string :entity_id, null: false, index: { unique: true }
      t.string :name
      t.integer :component_id
      t.integer :msa_component_id

      t.timestamps
    end
  end
end
