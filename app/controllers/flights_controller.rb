class FlightsController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'json'

  def submit
    search = params[:flight]
    unless search.is_a?(ActionController::Parameters) && valid_search?(search)
      return render json: { error: 'Choose two different three-letter airport codes and a valid departure date within the next year.' }, status: :unprocessable_entity
    end

    search_key = [search[:departureDate], search[:airportDeparture], search[:airportArrival]].join(':')
    client_ip = ENV['FLY_APP_NAME'].present? ? request.headers['Fly-Client-IP'].presence || 'unknown' : request.remote_ip
    guard = FlightSearchGuard.find_by(id: 1) || FlightSearchGuard.create_or_find_by!(id: 1)
    flights_data = guard.reserve(client_ip, search_key)
    unless flights_data
      api_url = "https://api.oag.com/flight-instances/"
      api_params = {
        version: "v2",
        DepartureDateTime: params.dig(:flight, :departureDate),
        CarrierCode: "QF,JQ,ANZ,VA",
        DepartureAirport: params.dig(:flight, :airportDeparture),
        ArrivalAirport: params.dig(:flight, :airportArrival),
        FlightType: "Scheduled",
        CodeType: "IATA",
        ServiceType: "Passenger",
        Limit: 10
      }

      query_string = URI.encode_www_form(api_params)

      uri = URI(api_url)
      uri.query = query_string

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 20) do |http|
        http.max_retries = 0
        req = Net::HTTP::Get.new(uri)
        req['Subscription-Key'] = ENV['OAG_API_KEY']
        http.request(req)
      end
    

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.warn("OAG flight search failed with HTTP #{response.code}")
        message = if %w[401 403].include?(response.code)
                    'Flight search is unavailable because OAG rejected access. Check the OAG subscription and API key.'
                  else
                    'The flight provider is unavailable. Please try again later.'
                  end
        return render json: { error: message }, status: :bad_gateway
      end

      flights_data = JSON.parse(response.body).fetch('data')
      raise TypeError, 'Expected a flight list' unless flights_data.is_a?(Array)

      raise TypeError, 'Expected flight objects' unless flights_data.all? { |flight| flight.is_a?(Hash) }
      guard.cache(search_key, flights_data)
    end

    flights_with_prices = flights_data.map do |flight|
      price = calculate_price(flight)
      details = {
        'schedule_key' => flight['scheduleInstanceKey'],
        'flight_number' => flight['flightNumber'].to_s,
        'carrier' => flight.dig('carrier', 'iata'),
        'date' => flight.dig('departure', 'date', 'local'),
        'from' => flight.dig('departure', 'airport', 'iata'),
        'to' => flight.dig('arrival', 'airport', 'iata')
      }
      flight_token = if details.values.all?(&:present?)
                       Rails.application.message_verifier(:flight_booking).generate(details, expires_in: 2.hours)
                     end
      flight.merge('price' => price, 'bookingToken' => flight_token)
    end
  
    render json: flights_with_prices, status: :ok
  rescue FlightSearchGuard::Limited => error
    headers['Retry-After'] = error.retry_after.to_s
    render json: { error: error.message }, status: :too_many_requests
  rescue ActiveRecord::ActiveRecordError
    render json: { error: 'Flight search is temporarily unavailable. Please try again later.' }, status: :service_unavailable
  rescue Timeout::Error
    render json: { error: 'The flight provider took too long to respond. Please try again.' }, status: :gateway_timeout
  rescue SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError
    render json: { error: 'Unable to reach the flight provider. Please try again later.' }, status: :bad_gateway
  rescue JSON::ParserError, KeyError, TypeError
    render json: { error: 'The flight provider returned an invalid response. Please try again later.' }, status: :bad_gateway
  end

  @all_flights = Flight.all
  def search
    origin = params[:from].upcase
    destination = params[:to].upcase
    @filtered_flights = []
    @all_flights.each do |flight|
      if flight.from == origin && flight.to == destination
        @filtered_flights << flight
      end
    end
    render json: @filtered_flights.empty? ? [] : @filtered_flights.to_json
  end

  def new
  end

  def edit
  end

  def show
    if params[:id].nil?
      return
    else
      flight_id = params[:id]
      @flight = Flight.find_by_id(flight_id)
      flight_data = []
      @plane = @flight.plane
      render json: flight_data.push(@plane, @flight)
    end
  end

  def destroy
  end

  private

  def valid_search?(search)
    departure = search[:airportDeparture]
    arrival = search[:airportArrival]
    date = search[:departureDate]
    return false unless [departure, arrival].all? { |airport| airport.is_a?(String) && airport.match?(/\A[A-Z]{3}\z/) }
    return false if departure == arrival
    return false unless date.is_a?(String) && date.match?(/\A\d{4}-\d{2}-\d{2}\z/)

    Date.iso8601(date).between?(Date.current, Date.current + 365)
  rescue ArgumentError
    false
  end
end

private

def use_cached_data?
  true
end

def calculate_price(flight)
  base_price = 100

  # Use elapsedTime as a proxy for distance
  estimated_duration = flight['elapsedTime'] || 0

  # Parse the departure time from the JSON structure
  departure_time_str = flight.dig('departure', 'time', 'utc')
  time_of_day = Time.parse(departure_time_str) rescue Time.now
  time_factor = case time_of_day.hour
                when 6..9, 17..20 then 0.8
                else 1.0
                end

  # Determine carrier type based on the carrier IATA code
  carrier_type = case flight.dig('carrier', 'iata')
                 when 'JQ' then 'budget'
                 when 'QF' then 'standard'
                 else 'standard'
                 end
  carrier_factor = case carrier_type
                   when 'budget' then 0.7
                   when 'standard' then 1.0
                   when 'premium' then 1.5
                   else 1.0
                   end

  # Calculate proximity factor based on days until departure
  departure_date_str = flight.dig('departure', 'date', 'utc')
  departure_date = Date.parse(departure_date_str) rescue Date.today
  days_until_departure = (departure_date - Date.today).to_i
  proximity_factor = if days_until_departure < 1
                       1.5
                      elsif days_until_departure < 3
                       1.3
                      elsif days_until_departure < 7
                       1.2
                      elsif days_until_departure < 30
                       1.1
                      else
                       1.0
                     end

  # Calculate the price using the estimated duration and factors
  price = base_price * (1 + estimated_duration / 100.0) * time_factor * carrier_factor * proximity_factor
  price.round(0)
end

def calculate_seat_price(seat_type)
  seat_factor = case seat_type
                when 'economy' then 0
                when 'business' then 150
                when 'first_class' then 300
                else 0
                end
  seat_factor
end
