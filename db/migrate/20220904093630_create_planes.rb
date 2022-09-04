class CreatePlanes < ActiveRecord::Migration[7.0]
  def change
    create_table :planes do |t|
      t.integer :rows
      t.integer :cols
      t.text :model
      t.integer :plane_id

      t.timestamps
    end
  end
end
