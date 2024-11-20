class FlightsController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'json'

  def submit
    if use_cached_data?
      # Use cached JSON data in development or testing
      file_path = Rails.root.join('lib', 'data', 'flights_data.json')
      flights_data = JSON.parse(File.read(file_path))['data'] # Access the 'data' key
    else
      # In production, construct the API call using credentials
      data = JSON.parse(request.body.read)
      departure_date = data['departureDate']
      arrival_date = data['arrivalDate']
      carrier_code = data['carrierCode']
      airport_departure = data['airportDeparture']
      airport_arrival = data['airportArrival']
  
      api_url = URI.parse("https://#{Rails.application.credentials.dig(:api, :host)}/schedules?version=v2&DepartureDateTime=#{departure_date}&ArrivalDateTime=#{arrival_date}&CarrierCode=#{carrier_code}&DepartureAirport=#{airport_departure}&ArrivalAirport=#{airport_arrival}&FlightType=Scheduled&CodeType=IATA&ServiceType=Passenger")
      
      http = Net::HTTP.new(api_url.host, api_url.port)
      http.use_ssl = true
  
      request = Net::HTTP::Get.new(api_url.request_uri)
      request["x-rapidapi-key"] = Rails.application.credentials.dig(:api, :key)
      request["x-rapidapi-host"] = Rails.application.credentials.dig(:api, :host)
  
      response = http.request(request)
      flights_data = JSON.parse(response.body)
    end
  
    flights_with_prices = flights_data.map do |flight|
      price = calculate_price(flight)
      flight.merge('price' => price)
    end
  
    render json: flights_with_prices
  end
  
  @all_flights = Flight.all
  def search
    origin = params[:from].upcase
    destination = params[:to].upcase
    @filtered_flights = []
    @all_flights.each do |flight|
      if flight.from == origin && flight.to == destination
        puts 'found a flight' + flight.id.to_s
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