class FlightsController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'json'

  def submit
    if use_cached_data?
      # Load the JSON data from the file
      file_path = Rails.root.join('lib', 'data', 'flights_data.json')
      flights_data = JSON.parse(File.read(file_path))['data'] # Access the 'data' key
    else
      # Existing API call logic
      data = JSON.parse(request.body.read)
      api_url = URI.parse(data['apiURL'])
  
      http = Net::HTTP.new(api_url.host, api_url.port)
      http.use_ssl = true
  
      request = Net::HTTP::Get.new(api_url.request_uri)
      request["x-rapidapi-key"] = 'f5abf39ffbmsh9e4b9bfefd110e5p127ac3jsn961f33097ba4'
      request["x-rapidapi-host"] = 'flight-info-api.p.rapidapi.com'
  
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

  # Add randomness to the price
  random_factor = 1 + rand(-0.05..0.05) # Randomly adjust price by ±5%

  # Calculate the price using the estimated duration and factors
  price = base_price * (1 + estimated_duration / 100.0) * time_factor * carrier_factor * proximity_factor * random_factor
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