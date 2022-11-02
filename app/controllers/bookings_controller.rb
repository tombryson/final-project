class BookingsController < ApplicationController
  def index
    @bookings = Booking.all
  end

  def create
    flight_id = params[:flight_id]
    occupy_booking = Booking.find_by(:flight_id => flight_id)
    p occupy_booking
    if occupy_booking.nil?
    @booking = Booking.create booking_params
    else
    render json: {message: 'Seat already booked'}
    end
  end

  def new
    @booking = Booking.new
  end

  def show
  end

  def edit
  end

  def destroy
  end

  private
  def booking_params 
    params.require(:booking).permit(:cols, :rows, :user_id, :flight_id)
  end

end
