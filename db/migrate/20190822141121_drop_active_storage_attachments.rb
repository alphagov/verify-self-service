class DropActiveStorageAttachments < ActiveRecord::Migration[5.2]
  def change
    drop_table :active_storage_attachments
  end
end
