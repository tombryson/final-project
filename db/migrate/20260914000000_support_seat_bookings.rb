class SupportSeatBookings < ActiveRecord::Migration[7.0]
  def change
    add_column :flights, :schedule_key, :string
    add_column :flights, :flight_number, :string
    add_column :flights, :carrier, :string
    add_index :flights, :schedule_key, unique: true

    change_column_null :bookings, :flight_id, false
    change_column_null :bookings, :user_id, false
    change_column_null :bookings, :rows, false
    change_column_null :bookings, :cols, false
    add_index :bookings, [:flight_id, :rows, :cols], unique: true
    add_index :bookings, :user_id
    add_foreign_key :bookings, :users
    add_foreign_key :bookings, :flights
  end
end
