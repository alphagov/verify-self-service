class AddComponentIdToCertificates < ActiveRecord::Migration[5.2]
  def change
    add_reference(:certificates, :component)
  end
end
