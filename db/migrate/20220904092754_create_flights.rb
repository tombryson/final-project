class CreateFlights < ActiveRecord::Migration[7.0]
  def change
    create_table :flights do |t|
      t.integer :plane_id
      t.date :date
      t.text :from
      t.text :to

      t.timestamps
    end
  end
end
