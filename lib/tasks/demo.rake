namespace :demo do
  desc 'Create the shared portfolio demo login without changing existing data'
  task setup: :environment do
    user = User.find_or_initialize_by(email: 'demo@burningairlines.test')
    if user.new_record?
      user.assign_attributes(first_name: 'Demo', last_name: 'User', password: 'demo1234', admin: false)
      user.save!
    end
    abort 'The demo email belongs to a different account. Check it before continuing.' if user.admin? || !user.authenticate('demo1234')
    puts 'Demo login ready: demo@burningairlines.test'
  end

  desc 'Clear bookings made through the shared demo login'
  task reset: :setup do
    user = User.find_by!(email: 'demo@burningairlines.test')
    user.with_lock do
      count = Booking.where(user_id: user.id).delete_all
      puts "Cleared #{count} shared demo bookings."
    end
  end
end
