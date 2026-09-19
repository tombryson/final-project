require 'digest'

class FlightSearchGuard < ApplicationRecord
  class Limited < StandardError
    attr_reader :retry_after

    def initialize(message, retry_after)
      super(message)
      @retry_after = retry_after
    end
  end

  def reserve(client_ip, search_key)
    result = nil
    with_lock do
      now = Time.current.to_i
      self.requests = requests.select { |time| time > now - 30.days.to_i }
      self.clients = clients.transform_values { |times| times.select { |time| time > now - 60 } }.reject { |_, times| times.empty? }
      self.searches = searches.select { |_, search| search['expires_at'] > now }
      client_key = Digest::SHA256.hexdigest(client_ip.to_s)
      attempts = clients[client_key] || []

      if attempts.length >= 5 || (!clients.key?(client_key) && clients.size >= 1000)
        result = Limited.new('Too many searches. Please wait a minute and try again.', 60)
      else
        clients[client_key] = attempts + [now]
        cached = searches[search_key]
        if cached && cached.key?('data')
          result = cached['data']
        elsif cached
          result = Limited.new('This search is already being checked. Please try again shortly.', 60)
        elsif requests.count { |time| time > now - 1.day.to_i } >= limit('OAG_DAILY_LIMIT', 10) || requests.length >= limit('OAG_30_DAY_LIMIT', 50)
          result = Limited.new('Live flight search has reached its demo allowance. Please try again later.', 3600)
        else
          requests << now
          searches[search_key] = { 'expires_at' => now + 60 }
        end
      end
      save!
    end
    raise result if result.is_a?(Limited)
    result
  end

  def cache(search_key, flights)
    with_lock do
      searches[search_key] = { 'expires_at' => 15.minutes.from_now.to_i, 'data' => flights }
      save!
    end
  end

  private

  def limit(name, default)
    [Integer(ENV.fetch(name, default.to_s)), 0].max
  rescue ArgumentError
    0
  end
end
