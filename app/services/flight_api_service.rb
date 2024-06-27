require 'uri'
require 'net/http'
require 'json'

url = URI("https://flight-info-api.p.rapidapi.com/schedules?version=v2&DepartureDateTime=2024-06-30&ArrivalDateTime=2024-06-30&CarrierCode=QF&DepartureAirport=MEL&ArrivalAirport=SYD&FlightType=Scheduled&CodeType=IATA&ServiceType=Passenger")

http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true

request = Net::HTTP::Get.new(url)
request["x-rapidapi-key"] = '06dc58e38cmsha755babd29559cap1aeaddjsn22ad0d99b516'
request["x-rapidapi-host"] = 'flight-info-api.p.rapidapi.com'

response = http.request(request)

# Parse and pretty-print the JSON response
parsed_response = JSON.parse(response.read_body)
puts JSON.pretty_generate(parsed_response)
