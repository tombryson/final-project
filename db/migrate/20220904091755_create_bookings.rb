class CreateBookings < ActiveRecord::Migration[7.0]
  def change
    create_table :bookings do |t|
      t.integer :rows
      t.integer :cols
      t.text :flight_id
      t.text :user_id

      t.timestamps
    end
  end
end
