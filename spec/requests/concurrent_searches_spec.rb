require 'rails_helper'

RSpec.describe 'Concurrent flight search limits' do
  self.use_transactional_tests = false

  before { FlightSearchGuard.delete_all }
  after { FlightSearchGuard.delete_all }

  def reserve_together(keys)
    ready = Queue.new
    start = Queue.new
    threads = keys.each_with_index.map do |key, i|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          guard = FlightSearchGuard.find_by(id: 1) || FlightSearchGuard.create_or_find_by!(id: 1)
          ready << true
          start.pop
          begin
            guard.reserve("client-#{i}", key)
            :reserved
          rescue FlightSearchGuard::Limited
            :limited
          end
        end
      end
    end
    keys.length.times { ready.pop }
    keys.length.times { start << true }
    threads.map(&:value)
  ensure
    threads&.each(&:join)
  end

  it 'reserves only one provider call when matching searches arrive together' do
    expect(reserve_together(['same-search', 'same-search']).sort).to eq([:limited, :reserved])
    expect(FlightSearchGuard.find(1).requests.length).to eq(1)
  end

  it 'does not exceed the daily cap when different searches compete for the final call' do
    FlightSearchGuard.create!(id: 1, requests: Array.new(9, Time.current.to_i))
    expect(reserve_together(['search-one', 'search-two']).sort).to eq([:limited, :reserved])
    expect(FlightSearchGuard.find(1).requests.length).to eq(10)
  end
end
