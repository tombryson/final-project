class CreateFlightSearchGuards < ActiveRecord::Migration[7.0]
  def change
    create_table :flight_search_guards do |t|
      t.jsonb :requests, null: false, default: []
      t.jsonb :clients, null: false, default: {}
      t.jsonb :searches, null: false, default: {}
    end
    reversible do |direction|
      direction.up { execute 'INSERT INTO flight_search_guards (id) VALUES (1)' }
    end
  end
end
