require 'rails_helper'

RSpec.describe FlightsController, type: :controller do
  let(:search) do
    { flight: { departureDate: '2026-09-14', airportDeparture: 'MEL', airportArrival: 'SYD' } }
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

  it 'escapes search values so they cannot inject provider query parameters' do
    provider = Net::HTTPOK.new('1.1', '200', '')
    allow(provider).to receive(:body).and_return({ data: [] }.to_json)
    http = double('provider connection')
    allow(Net::HTTP).to receive(:start).and_yield(http)
    expect(http).to receive(:request) do |request|
      query = URI.decode_www_form(request.path.split('?', 2).last).to_h
      expect(query['DepartureAirport']).to eq('MEL&CarrierCode=OTHER')
      expect(query['CarrierCode']).to eq('QF,JQ,ANZ,VA')
      provider
    end
    post :submit, params: { flight: search[:flight].merge(airportDeparture: 'MEL&CarrierCode=OTHER') }
    expect(response).to have_http_status(:ok)
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
