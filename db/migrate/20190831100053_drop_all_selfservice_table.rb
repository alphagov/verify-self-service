class DropAllSelfserviceTable < ActiveRecord::Migration[5.2]
  def up
    drop_table "certificates" , if_exists: true
    drop_table "events" , if_exists: true
    drop_table "msa_components" , if_exists: true
    drop_table "services" , if_exists: true
    drop_table "sp_components" , if_exists: true
    drop_table "teams" , if_exists: true
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
