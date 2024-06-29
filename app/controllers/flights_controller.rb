class FlightsController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'json'
  
  # def index
  #   @flights = Flight.all
  #   @planes = Plane.all
  # end

  def submit
    data = JSON.parse(request.body.read)
    api_url = URI.parse(data['apiURL'])

    http = Net::HTTP.new(api_url.host, api_url.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(api_url.request_uri)
    request["x-rapidapi-key"] = 'f5abf39ffbmsh9e4b9bfefd110e5p127ac3jsn961f33097ba4'
    request["x-rapidapi-host"] = 'flight-info-api.p.rapidapi.com'

    response = http.request(request)
    @flights = JSON.parse(response.body)
    
    render json: @flights
  end
  
  def search
    @all_flights = Flight.all
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
