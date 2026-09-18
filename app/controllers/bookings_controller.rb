class BookingsController < ApplicationController
  before_action :require_login

  def index
    bookings = session_user.bookings.includes(:flight).order(created_at: :desc)
    render json: bookings.as_json(include: :flight)
  end

  def show
    booking = session_user.bookings.find_by(id: params[:id])
    if booking
      render json: booking.as_json(include: :flight)
    else
      render json: { error: 'Booking not found.' }, status: :not_found
    end
  end

  def create
    details = booking_params
    flight_data = Rails.application.message_verifier(:flight_booking).verify(details[:flight_token])

    Booking.transaction do
      flight = Flight.create_or_find_by!(schedule_key: flight_data.fetch('schedule_key')) do |new_flight|
        new_flight.assign_attributes(flight_data.except('schedule_key'))
        new_flight.plane = Plane.find_or_create_by!(model: 'Demo aircraft', rows: 28, cols: 6)
      end
      booking = session_user.bookings.create!(flight: flight, rows: details[:rows], cols: details[:cols])
      render json: booking.as_json(include: :flight), status: :created
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature, KeyError, TypeError
    render json: { error: 'Please search again and select a flight.' }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotUnique
    render json: { error: 'That seat is taken. Please choose another seat.' }, status: :conflict
  rescue ActiveRecord::RecordInvalid => error
    render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  rescue ActionController::ParameterMissing
    render json: { error: 'Select a flight and seat before booking.' }, status: :unprocessable_entity
  end

  def destroy
    booking = session_user.bookings.find_by(id: params[:id])
    unless booking
      return render json: { error: 'Booking not found.' }, status: :not_found
    end

    booking.destroy!
    head :no_content
  end

  private

  def booking_params
    params.require(:booking).permit(:flight_token, :rows, :cols)
  end
end
