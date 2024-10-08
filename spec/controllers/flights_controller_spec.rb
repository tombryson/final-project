require 'rails_helper'

RSpec.describe FlightsController, type: :controller do
  describe 'POST #submit' do
    context 'when using cached JSON data' do
      it 'returns flights with prices and prints them' do
        # Stub the use_cached_data? method to return true
        allow_any_instance_of(FlightsController).to receive(:use_cached_data?).and_return(true)

        # Make a POST request to the submit action
        post :submit

        # Parse the JSON response
        json_response = JSON.parse(response.body)

        # Check that the response is successful
        expect(response).to have_http_status(:success)

        # Check that the response contains flights with prices
        expect(json_response).to all(include('price'))

        # Print out the prices of the flights
        json_response.each do |flight|
          puts "Flight #{flight['flightNumber']} has a price of $#{flight['price']}"
        end
      end
    end
  end
end