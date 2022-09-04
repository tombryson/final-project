User.destroy_all
puts "Creating users..."
u1 = User.create :first_name => "John", :last_name => "Smith", :email => "admin@ga.co", :password => "chicken", :admin => true
u2 = User.create :first_name => "Tom", :last_name => "Anderson", :email => "a@ga.co", :password => "chicken"

Flight.destroy_all
puts "Creating flights..."
f1 = Flight.create :flight_id => "32", :date => DateTime.new(2022, 9, 22), :to => "JFK", :from => "SYD", :plane => "747"
f2 = Flight.create :flight_id => "63", :date => DateTime.new(2022, 10, 14), :to => "LAX", :from => "CDG", :plane => "757"
puts "#{Flight.count} flights created."

Plane.destroy_all
puts "Creating planes..."
a1 = Plane.create :name => "747", :rows => 24, :cols => 4
a2 = Plane.create :name => "757", :rows => 15, :cols => 4
a3 = Plane.create :name => "727", :rows => 12, :cols => 4
puts "#{Plane.count} planes created."