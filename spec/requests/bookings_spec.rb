require 'rails_helper'

RSpec.describe 'Booking a seat', type: :request do
  before { host! 'burning-airlines.fly.dev' }
  let!(:user) { User.create!(email: 'booking-owner@example.test', password: 'booking-password', first_name: 'Owner') }
  let!(:other_user) { User.create!(email: 'booking-other@example.test', password: 'other-password', first_name: 'Other') }
  let(:flight_details) do
    { 'schedule_key' => 'test-MEL-SYD-2026-09-15-QF400', 'flight_number' => '400',
      'carrier' => 'QF', 'date' => '2026-09-15', 'from' => 'MEL', 'to' => 'SYD' }
  end
  let(:flight_token) { Rails.application.message_verifier(:flight_booking).generate(flight_details, expires_in: 2.hours) }

  def sign_in(email = user.email, password = 'booking-password')
    post '/login', params: { email: email, password: password }, as: :json
    expect(response).to have_http_status(:ok)
    { 'Authorization' => "Bearer #{JSON.parse(response.body).fetch('jwt')}" }
  end

  def book(headers, row = 12, col = 0, token = flight_token)
    post '/bookings', params: { booking: { flight_token: token, rows: row, cols: col, user_id: other_user.id } }, headers: headers, as: :json
  end

  it 'saves a booking for the authenticated user and reloads it through My Flights' do
    headers = sign_in
    book(headers)
    expect(response).to have_http_status(:created)
    data = JSON.parse(response.body)
    expect(data).to include('user_id' => user.id, 'rows' => 12, 'cols' => 0)
    expect(data.fetch('flight')).to include('from' => 'MEL', 'to' => 'SYD', 'date' => '2026-09-15')
    expect(Booking.find(data['id']).user).to eq(user)

    get '/bookings', headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).map { |trip| trip['id'] }).to eq([data['id']])
  end

  it 'rejects the same seat for a second user but permits another seat' do
    first_headers = sign_in
    second_headers = sign_in(other_user.email, 'other-password')
    book(first_headers)
    book(second_headers)
    expect(response).to have_http_status(:conflict)
    expect(Booking.where(flight: Flight.find_by(schedule_key: flight_details['schedule_key'])).count).to eq(1)
    book(second_headers, 12, 1)
    expect(response).to have_http_status(:created)
    expect(Flight.where(schedule_key: flight_details['schedule_key']).count).to eq(1)
  end

  it 'does not return another user’s booking' do
    book(sign_in)
    booking_id = JSON.parse(response.body)['id']
    headers = sign_in(other_user.email, 'other-password')
    get '/bookings', headers: headers
    expect(JSON.parse(response.body)).to eq([])
    get "/bookings/#{booking_id}", headers: headers
    expect(response).to have_http_status(:not_found)
    get "/users/#{user.id}", headers: headers
    expect(response).to have_http_status(:not_found)
  end

  it 'requires authentication' do
    book({})
    expect(response).to have_http_status(:unauthorized)
    get '/bookings'
    expect(response).to have_http_status(:unauthorized)
    get '/auto_login'
    expect(response).to have_http_status(:unauthorized)
    get '/users'
    expect(response).to have_http_status(:unauthorized)
  end

  it 'authenticates an existing user instead of creating one and never exposes a password hash' do
    expect { sign_in }.not_to change(User, :count)
    expect(JSON.parse(response.body).fetch('user')).not_to have_key('password_digest')
    headers = sign_in
    get '/auto_login', headers: headers
    expect(JSON.parse(response.body)).to include('id' => user.id)
    expect(JSON.parse(response.body)).not_to have_key('password_digest')
  end

  it 'rejects an incorrect password' do
    post '/login', params: { email: user.email, password: 'incorrect' }, as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(JSON.parse(response.body)).not_to have_key('jwt')
  end

  it 'rejects forged and expired bearer tokens' do
    forged = JWT.encode({ user_id: user.id }, 'incorrect-secret', 'HS256')
    expired = JWT.encode({ user_id: user.id, exp: 1.minute.ago.to_i }, Rails.application.secret_key_base, 'HS256')
    [forged, expired].each do |token|
      get '/bookings', headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  it 'does not allow signup to grant administrator privileges' do
    post '/users', params: { email: 'normal-user@example.test', password: 'normal-password', admin: true }, as: :json
    expect(response).to have_http_status(:created)
    expect(User.find_by!(email: 'normal-user@example.test').admin?).to eq(false)
  end

  it 'supports signup followed by authenticated requests and blocks duplicate signup' do
    post '/users', params: { email: 'NEW@example.test', password: 'new-password' }, as: :json
    expect(response).to have_http_status(:created)
    data = JSON.parse(response.body)
    expect(data['user']['email']).to eq('new@example.test')
    expect(data['user']).not_to have_key('password_digest')
    get '/auto_login', headers: { 'Authorization' => "Bearer #{data['jwt']}" }
    expect(response).to have_http_status(:ok)
    post '/users', params: { email: 'new@example.test', password: 'another-password' }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
  end

  [[0, 0], [29, 0], [12, -1], [12, 6], [nil, 0], ['abc', 0]].each do |row, col|
    it "rejects invalid seat coordinates #{[row, col].inspect}" do
      expect { book(sign_in, row, col) }.not_to change(Booking, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  it 'rejects altered and expired flight references' do
    headers = sign_in
    book(headers, 12, 0, 'changed-flight-details')
    expect(response).to have_http_status(:unprocessable_entity)
    expired = Rails.application.message_verifier(:flight_booking).generate(flight_details, expires_in: -1.second)
    book(headers, 12, 0, expired)
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'handles missing booking parameters' do
    post '/bookings', params: {}, headers: sign_in, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'cancels an owned booking, keeps the flight and frees the seat for another user' do
    headers = sign_in
    book(headers)
    booking = Booking.find(JSON.parse(response.body)['id'])
    flight_id = booking.flight_id

    expect { delete "/bookings/#{booking.id}", headers: headers }.to change(Booking, :count).by(-1)
    expect(response).to have_http_status(:no_content)
    expect(Flight.exists?(flight_id)).to eq(true)
    get '/bookings', headers: headers
    expect(JSON.parse(response.body)).to eq([])

    book(sign_in(other_user.email, 'other-password'))
    expect(response).to have_http_status(:created)
    expect(JSON.parse(response.body)['flight_id']).to eq(flight_id)
  end

  it 'cannot cancel another user’s booking' do
    book(sign_in)
    booking_id = JSON.parse(response.body)['id']
    headers = sign_in(other_user.email, 'other-password')
    expect { delete "/bookings/#{booking_id}", headers: headers }.not_to change(Booking, :count)
    expect(response).to have_http_status(:not_found)
  end

  it 'requires login to cancel a booking' do
    book(sign_in)
    booking_id = JSON.parse(response.body)['id']
    expect { delete "/bookings/#{booking_id}" }.not_to change(Booking, :count)
    expect(response).to have_http_status(:unauthorized)
  end

  it 'returns not found if a booking has already been cancelled' do
    headers = sign_in
    book(headers)
    booking_id = JSON.parse(response.body)['id']
    delete "/bookings/#{booking_id}", headers: headers
    expect { delete "/bookings/#{booking_id}", headers: headers }.not_to change(Booking, :count)
    expect(response).to have_http_status(:not_found)
  end
end
