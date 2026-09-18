require 'rails_helper'

RSpec.describe 'Two users booking together', type: :request do
  self.use_transactional_tests = false

  it 'lets exactly one request claim the seat, including when the flight has not been saved yet' do
    key = "concurrent-booking-#{SecureRandom.hex(8)}"
    users = 2.times.map { |i| User.create!(email: "#{key}-#{i}@example.test", password: 'test-password') }
    details = { 'schedule_key' => key, 'flight_number' => '400', 'carrier' => 'QF',
                'date' => '2026-09-15', 'from' => 'MEL', 'to' => 'SYD' }
    flight_token = Rails.application.message_verifier(:flight_booking).generate(details, expires_in: 2.hours)
    ready = Queue.new
    start = Queue.new
    threads = users.map do |user|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          token = JWT.encode({ user_id: user.id, exp: 1.hour.from_now.to_i }, Rails.application.secret_key_base, 'HS256')
          session = ActionDispatch::Integration::Session.new(Rails.application)
          session.host! 'burning-airlines.fly.dev'
          ready << true
          start.pop
          session.post '/bookings', params: { booking: { flight_token: flight_token, rows: 12, cols: 0 } },
                                   headers: { 'Authorization' => "Bearer #{token}" }, as: :json
          session.response.status
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    expect(threads.map(&:value).sort).to eq([201, 409])
    expect(Flight.where(schedule_key: key).count).to eq(1)
    expect(Booking.where(user_id: users.map(&:id)).count).to eq(1)
  ensure
    threads&.each(&:join)
    Booking.where(user_id: users.map(&:id)).delete_all if users
    Flight.where(schedule_key: key).delete_all if key
    User.where(id: users.map(&:id)).delete_all if users
  end
end
