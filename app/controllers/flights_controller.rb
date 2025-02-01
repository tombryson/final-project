class FlightsController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'json'

  def submit
    api_url = "https://flight-info-api.p.rapidapi.com/schedules"
    api_params = {
      version: "v2",
      DepartureDateTime: params.dig(:flight, :departureDate),
      CarrierCode: "QF,JQ,ANZ,VA",
      DepartureAirport: params.dig(:flight, :airportDeparture),
      ArrivalAirport: params.dig(:flight, :airportArrival),
      FlightType: "Scheduled",
      CodeType: "IATA",
      ServiceType: "Passenger"
    }

    query_string = "version=#{api_params[:version]}" +
                   "&DepartureDateTime=#{api_params[:DepartureDateTime]}" +
                   "&CarrierCode=#{api_params[:CarrierCode]}" +
                   "&DepartureAirport=#{api_params[:DepartureAirport]}" +
                   "&ArrivalAirport=#{api_params[:ArrivalAirport]}" +
                   "&FlightType=#{api_params[:FlightType]}" +
                   "&CodeType=#{api_params[:CodeType]}" +
                   "&ServiceType=#{api_params[:ServiceType]}"

    uri = URI(api_url)
    uri.query = query_string

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      req = Net::HTTP::Get.new(uri)
      req['X-RapidAPI-Key'] = ENV['RAPID_API_KEY']
      req['X-RapidAPI-Host'] = 'flight-info-api.p.rapidapi.com'
      http.request(req)
    end
      
    flights_data = JSON.parse(response.body)['data'] || []

    # Mock data in development environment
    # puts "Using mock data from public/mock_return_flights.json"
    # mock_file_path = Rails.root.join('public', 'mock_return_flights.json')
    # file_contents = File.read(mock_file_path)
    # flights_data = JSON.parse(file_contents) || []
    #####MOCK##############MOCK###############MOCK##################MOCK###################MOCK############MOCK#######

    flights_with_prices = flights_data.map do |flight|
      price = calculate_price(flight)
      flight.merge('price' => price)
    end
    puts "flights_with_prices: #{flights_with_prices}"
  
    render json: flights_with_prices, status: :ok
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