require 'uri'
require 'net/http'
require 'json'

class FlightApiService
  def self.fetch_schedules
    url = URI("https://flight-info-api.p.rapidapi.com/schedules?version=v2&DepartureDateTime=2024-06-30&ArrivalDateTime=2024-06-30&CarrierCode=QF&DepartureAirport=MEL&ArrivalAirport=SYD&FlightType=Scheduled&CodeType=IATA&ServiceType=Passenger")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 20

    request = Net::HTTP::Get.new(url)
    request["x-rapidapi-key"] = ENV.fetch("RAPIDAPI_KEY")
    request["x-rapidapi-host"] = 'flight-info-api.p.rapidapi.com'

    response = http.request(request)

    JSON.parse(response.read_body)
  end
end
