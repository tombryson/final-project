class FlightsController < ApplicationController
  def index
    @flights = Flight.all
  end
  
  def search
    @all_flights = Flight.all
    origin = params[:from].upcase
    destination = params[:to].upcase
    @filtered_flights = []
    @all_flights.each do |flight|
      if flight.from == origin && flight.to == destination
        @filtered_flights << flight
      end
    end
  end

  def new
  end

  def edit
  end

  def show
  end

  def destroy
  end
end
