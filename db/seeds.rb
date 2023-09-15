User.destroy_all
puts "Creating users..."
u1 = User.create :first_name => "John", :last_name => "Smith", :email => "admin@ga.co", :password => "chicken", :admin => true
u2 = User.create :first_name => "Tom", :last_name => "Anderson", :email => "a@ga.co", :password => "chicken"

Plane.destroy_all
puts "Creating planes..."
p1 = Plane.create :rows => 27, :cols => 6, :model => "B737"
p2 = Plane.create :rows => 42, :cols => 8, :model => "A330"

Flight.destroy_all
puts "Creating flights..."
f1 = Flight.create :plane_id => p1.id, :date => DateTime.new(2022, 9, 22), :from => "SYD", :to => "HND"
f2 = Flight.create :plane_id => p1.id, :date => DateTime.new(2022, 10, 14), :from => "MEL", :to => "AKL"
f3 = Flight.create :plane_id => p2.id, :date => DateTime.new(2022, 11, 19), :from => "SYD", :to => "HND"
puts "#{Flight.count} flights created."

Booking.destroy_all
puts "Creating bookings..."
a1 = Booking.create :user => u1, :flight => f1, :rows => 27, :cols => 6
a2 = Booking.create :user => u2, :flight => f2, :rows => 42, :cols => 8
puts "#{Booking.count} bookings created."

