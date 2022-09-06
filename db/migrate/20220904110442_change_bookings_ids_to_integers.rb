class ChangeBookingsIdsToIntegers < ActiveRecord::Migration[7.0]
  def change
    change_column :bookings, :user_id, 'integer USING CAST(user_id AS integer)'
    change_column :bookings, :flight_id, 'integer USING CAST(flight_id AS integer)'
  end
end
