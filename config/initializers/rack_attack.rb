# class Rack::Attack
#     throttle("requests by ip", limit: 5, period: 60) do |req|
#       req.ip if req.path == '/flights'
#     end
#   end
  