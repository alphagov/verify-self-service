class RemoveComponentTable < ActiveRecord::Migration[5.2]
  def change
    drop_table :components
  end
end
