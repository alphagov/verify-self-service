class AddHubUseNotificationToCertificate < ActiveRecord::Migration[6.0]
  def change
    add_column :certificates, :in_use_at, :datetime, null: true
    add_column :certificates, :notification_sent, :boolean, null: false, default: false
  end
end
