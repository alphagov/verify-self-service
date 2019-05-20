class AddEntityIdToComponents < ActiveRecord::Migration[5.2]
  def change
    add_column :components, :entity_id, :string
  end
end
