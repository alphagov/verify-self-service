class AddReferencesToMsaComponents < ActiveRecord::Migration[5.2]
  def change
    add_reference :msa_components, :team, foreign_key: true
  end
end
