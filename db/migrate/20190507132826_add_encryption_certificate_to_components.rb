class AddEncryptionCertificateToComponents < ActiveRecord::Migration[5.2]
  def change
    add_column :components, :encryption_certificate_id, :integer
  end
end
