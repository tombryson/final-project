class FlightsController < ApplicationController
  def index
    @flights = Flight.all
    @planes = Plane.all
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
    flight_id = params[:id]
    @flight = Flight.find_by_id(flight_id)
    flight_data = []
    @plane = @flight.plane
    render json: flight_data.push(@plane, @flight)
  end

  def destroy
  end
end
