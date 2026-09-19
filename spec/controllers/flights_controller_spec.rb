require 'rails_helper'

RSpec.describe FlightsController, type: :controller do
  include ActiveSupport::Testing::TimeHelpers
  let(:search) do
    { flight: { departureDate: Date.current.iso8601, airportDeparture: 'MEL', airportArrival: 'SYD' } }
  end

  def provider_response(response_class, code, body)
    response = response_class.new('1.1', code, '')
    allow(response).to receive(:body).and_return(body)
    allow(Net::HTTP).to receive(:start).and_return(response)
  end

  it 'returns provider flights with calculated prices' do
    provider_response(Net::HTTPOK, '200', { data: [{ flightNumber: '400', elapsedTime: 90 }] }.to_json)
    post :submit, params: search
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to contain_exactly(include('flightNumber' => '400', 'price' => a_kind_of(Numeric)))
  end

  it 'preserves a successful empty search' do
    provider_response(Net::HTTPOK, '200', { data: [] }.to_json)
    post :submit, params: search
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq([])
  end

  it 'rejects injected provider query parameters without calling OAG' do
    expect(Net::HTTP).not_to receive(:start)
    post :submit, params: { flight: search[:flight].merge(airportDeparture: 'MEL&CarrierCode=OTHER') }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'rejects missing, malformed and unbounded searches without calling OAG' do
    expect(Net::HTTP).not_to receive(:start)
    [{}, { flight: 'bad' }, { flight: search[:flight].merge(airportArrival: 'MEL') },
     { flight: search[:flight].merge(departureDate: '2026-02-30') },
     { flight: search[:flight].merge(departureDate: (Date.current + 366).iso8601) },
     { flight: search[:flight].merge(airportArrival: ['SYD']) }].each do |invalid|
      post :submit, params: invalid
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  it 'uses cached results but issues a fresh signed booking reference' do
    flight = { scheduleInstanceKey: 'cached-flight', flightNumber: '400', carrier: { iata: 'QF' },
               departure: { date: { local: Date.current.iso8601 }, airport: { iata: 'MEL' } },
               arrival: { airport: { iata: 'SYD' } } }
    provider_response(Net::HTTPOK, '200', { data: [flight] }.to_json)
    post :submit, params: search
    first_token = JSON.parse(response.body).first.fetch('bookingToken')
    travel 1.minute do
      post :submit, params: search
      expect(response).to have_http_status(:ok)
      token = JSON.parse(response.body).first.fetch('bookingToken')
      expect(token).not_to eq(first_token)
      expect(Rails.application.message_verifier(:flight_booking).verify(token)['schedule_key']).to eq('cached-flight')
    end
    expect(Net::HTTP).to have_received(:start).once
  end

  it 'limits repeat searches before contacting OAG again' do
    provider_response(Net::HTTPOK, '200', { data: [] }.to_json)
    5.times { post :submit, params: search; expect(response).to have_http_status(:ok) }
    post :submit, params: search
    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers['Retry-After']).to eq('60')
    expect(Net::HTTP).to have_received(:start).once
  end

  it 'fails closed when PostgreSQL cannot enforce the allowance' do
    allow(FlightSearchGuard).to receive(:find_by).and_raise(ActiveRecord::ConnectionNotEstablished)
    expect(Net::HTTP).not_to receive(:start)
    post :submit, params: search
    expect(response).to have_http_status(:service_unavailable)
  end

  it 'does not let forwarded IP headers bypass the Fly client limit' do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('FLY_APP_NAME').and_return('burning-airlines')
    request.headers['Fly-Client-IP'] = '198.51.100.1'
    provider_response(Net::HTTPOK, '200', { data: [] }.to_json)
    6.times do |i|
      request.headers['X-Forwarded-For'] = "203.0.113.#{i}"
      post :submit, params: search
    end
    expect(response).to have_http_status(:too_many_requests)
    expect(Net::HTTP).to have_received(:start).once
  end

  it 'does not automatically retry a failed HTTP request' do
    http = double('provider connection')
    allow(Net::HTTP).to receive(:start).and_yield(http)
    expect(http).to receive(:max_retries=).with(0)
    expect(http).to receive(:request).once.and_raise(Net::ReadTimeout)
    post :submit, params: search
    expect(response).to have_http_status(:gateway_timeout)
    expect(FlightSearchGuard.find(1).requests.length).to eq(1)
  end

  it 'reports rejected provider access instead of an empty successful search' do
    provider_response(Net::HTTPUnauthorized, '401', { message: 'Access denied due to expired subscription.' }.to_json)
    post :submit, params: search
    expect(response).to have_http_status(:bad_gateway)
    expect(JSON.parse(response.body).fetch('error')).to include('subscription and API key')
  end

  it 'rejects an unexpected provider payload' do
    provider_response(Net::HTTPOK, '200', { message: 'Unexpected response' }.to_json)
    post :submit, params: search
    expect(response).to have_http_status(:bad_gateway)
    expect(JSON.parse(response.body).fetch('error')).to include('invalid response')
  end

  it 'reports provider timeouts' do
    allow(Net::HTTP).to receive(:start).and_raise(Net::ReadTimeout)
    post :submit, params: search
    expect(response).to have_http_status(:gateway_timeout)
    expect(JSON.parse(response.body).fetch('error')).to include('too long')
  end

  it 'reports an unreachable provider' do
    allow(Net::HTTP).to receive(:start).and_raise(SocketError)
    post :submit, params: search
    expect(response).to have_http_status(:bad_gateway)
    expect(JSON.parse(response.body).fetch('error')).to include('Unable to reach')
  end
end
