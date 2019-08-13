class DropUsersTable < ActiveRecord::Migration[5.2]
  def up
    drop_table :users
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
