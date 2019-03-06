class CreateEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :events do |t|
      t.string :type, null: false
      t.json :data
      t.references :aggregate, polymorphic: true

      t.timestamps
    end
  end
end
