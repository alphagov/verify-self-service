class CreateCertificates < ActiveRecord::Migration[5.2]
  def change
    create_table :certificates do |t|
      t.string :value,
      t.string :usage
      t.timestamps
    end
  end
end
