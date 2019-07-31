class AddReferencesToSpComponents < ActiveRecord::Migration[5.2]
  def change
    add_reference :sp_components, :team, foreign_key: true
  end
end
