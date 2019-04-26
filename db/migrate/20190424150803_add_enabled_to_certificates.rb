class AddEnabledToCertificates < ActiveRecord::Migration[5.2]
  def change
    add_column :certificates, :enabled, :boolean, default: true
  end
end
