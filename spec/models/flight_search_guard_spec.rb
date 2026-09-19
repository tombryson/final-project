require 'rails_helper'

RSpec.describe FlightSearchGuard do
  include ActiveSupport::Testing::TimeHelpers
  let(:guard) { FlightSearchGuard.find_by(id: 1) || FlightSearchGuard.create!(id: 1) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('OAG_DAILY_LIMIT', '10').and_return('10')
    allow(ENV).to receive(:fetch).with('OAG_30_DAY_LIMIT', '50').and_return('50')
  end

  it 'enforces a shared daily cap across different IPs and fresh model instances' do
    10.times { |i| guard.reserve("client-#{i}", "search-#{i}") }
    expect { FlightSearchGuard.find(1).reserve('another-client', 'another-search') }.to raise_error(FlightSearchGuard::Limited)
    expect(guard.reload.requests.length).to eq(10)
    travel 1.day + 1.second do
      expect(FlightSearchGuard.find(1).reserve('another-client', 'another-search')).to be_nil
    end
  end

  it 'enforces the rolling 30-day cap even when the daily allowance is free' do
    guard.update!(requests: Array.new(50, 2.days.ago.to_i))
    expect { guard.reserve('client', 'search') }.to raise_error(FlightSearchGuard::Limited)
    travel 29.days do
      expect(guard.reserve('client', 'search')).to be_nil
    end
  end

  it 'serves cached results after reaching the provider cap' do
    guard.cache('cached', [])
    guard.update!(requests: Array.new(10, Time.current.to_i))
    expect(guard.reserve('client', 'cached')).to eq([])
    expect { guard.reserve('client', 'uncached') }.to raise_error(FlightSearchGuard::Limited)
  end

  it 'expires cached results and charges for their refresh' do
    guard.cache('search', [])
    travel 16.minutes do
      expect(guard.reserve('client', 'search')).to be_nil
      expect(guard.reload.requests.length).to eq(1)
    end
  end

  it 'keeps the reservation when a provider call fails and delays repeat attempts' do
    guard.reserve('client', 'failed-search')
    expect { FlightSearchGuard.find(1).reserve('another-client', 'failed-search') }.to raise_error(FlightSearchGuard::Limited)
    expect(guard.reload.requests.length).to eq(1)
  end

  it 'stops live calls when the configured allowance is zero or invalid' do
    ['0', 'invalid', '-10'].each do |value|
      allow(ENV).to receive(:fetch).with('OAG_DAILY_LIMIT', '10').and_return(value)
      expect { guard.reserve('client', 'search') }.to raise_error(FlightSearchGuard::Limited)
    end
    expect(guard.reload.requests).to be_empty
  end
end
