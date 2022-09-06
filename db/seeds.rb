User.destroy_all
puts "Creating users..."
user1 = User.create(username: "sample", password: "sample")
u1 = User.create :first_name => "John", :last_name => "Smith", :email => "admin@ga.co", :password => "chicken", :admin => true
u2 = User.create :first_name => "Tom", :last_name => "Anderson", :email => "a@ga.co", :password => "chicken"

Booking.destroy_all
puts "Creating bookings..."
a1 = Booking.create :user_id => "1", :flight_id => "1", :rows => 27, :cols => 6
a2 = Booking.create :user_id => "2", :flight_id => "2", :rows => 42, :cols => 8
puts "#{Booking.count} planes created."

Flight.destroy_all
puts "Creating flights..."
f1 = Flight.create :flight_id => "1", :date => DateTime.new(2022, 9, 22), :from => "SYD", :to => "HND", :plane_id => "B737"
f2 = Flight.create :flight_id => "2", :date => DateTime.new(2022, 10, 14), :from => "MEL", :to => "AKL", :plane_id => "A330"
puts "#{Flight.count} flights created."

Plane.destroy_all
puts "Creating planes..."
a1 = Plane.create :name => "B737", :rows => 27, :cols => 6
a2 = Plane.create :name => "A330", :rows => 42, :cols => 8
puts "#{Plane.count} planes created."

