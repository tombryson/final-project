require 'rails_helper'
require 'rake'

Rails.application.load_tasks unless Rake::Task.task_defined?('demo:setup')

RSpec.describe 'Demo account tasks' do
  before do
    Rake::Task['demo:setup'].reenable
    Rake::Task['demo:reset'].reenable
  end

  it 'creates a regular demo user and can run again without creating duplicates' do
    expect { Rake::Task['demo:setup'].invoke }.to change(User, :count).by(1)
    user = User.find_by!(email: 'demo@burningairlines.test')
    expect(user.admin).to eq(false)
    expect(user.authenticate('demo1234')).to eq(user)

    Rake::Task['demo:setup'].reenable
    expect { Rake::Task['demo:setup'].invoke }.not_to change(User, :count)
  end

  it 'clears only shared demo bookings, retains flight data and lets the seat be booked again' do
    Rake::Task['demo:setup'].invoke
    demo = User.find_by!(email: 'demo@burningairlines.test')
    owner = User.create!(email: 'retained-user@example.test', password: 'owner-password')
    plane = Plane.create!(model: 'Test aircraft', rows: 28, cols: 6)
    flight = Flight.create!(plane: plane, date: '2026-09-15', from: 'MEL', to: 'SYD')
    demo_booking = demo.bookings.create!(flight: flight, rows: 12, cols: 0)
    owner_booking = owner.bookings.create!(flight: flight, rows: 12, cols: 1)

    expect { Rake::Task['demo:reset'].invoke }.to change(Booking, :count).by(-1)
    expect(Booking.exists?(demo_booking.id)).to eq(false)
    expect(Booking.exists?(owner_booking.id)).to eq(true)
    expect(User.exists?(owner.id)).to eq(true)
    expect(Flight.exists?(flight.id)).to eq(true)
    expect(Plane.exists?(plane.id)).to eq(true)
    expect(demo.reload.authenticate('demo1234')).to eq(demo)
    expect { demo.bookings.create!(flight: flight, rows: 12, cols: 0) }.to change(Booking, :count).by(1)
  end

  it 'refuses to reuse an administrator account with the public credentials' do
    User.create!(email: 'demo@burningairlines.test', password: 'demo1234', admin: true)
    expect { Rake::Task['demo:reset'].invoke }.to raise_error(SystemExit)
  end

  it 'refuses to overwrite an existing account with a different password' do
    user = User.create!(email: 'demo@burningairlines.test', password: 'existing-password')
    expect { Rake::Task['demo:setup'].invoke }.to raise_error(SystemExit)
    expect(user.reload.authenticate('existing-password')).to eq(user)
  end
end
