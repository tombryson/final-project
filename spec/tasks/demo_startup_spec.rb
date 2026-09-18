require 'rails_helper'
require 'tmpdir'
require 'open3'

RSpec.describe 'Demo container startup' do
  def run_startup(demo_mode)
    Dir.mktmpdir('demo-startup') do |directory|
      File.write("#{directory}/bundle", <<~SH)
        #!/bin/sh
        printf '%s\n' "$*" >> "$DEMO_LOG"
      SH
      File.write("#{directory}/sleep", <<~SH)
        #!/bin/sh
        printf 'sleep %s\n' "$1" >> "$DEMO_LOG"
        if [ "$1" = "86400" ]; then
          if [ -f "$DEMO_TICK" ]; then exit 1; fi
          touch "$DEMO_TICK"
        fi
      SH
      File.chmod(0755, "#{directory}/bundle", "#{directory}/sleep")
      environment = {
        'PATH' => "#{directory}:#{ENV.fetch('PATH')}", 'DEMO_MODE' => demo_mode,
        'DEMO_LOG' => "#{directory}/calls", 'DEMO_TICK' => "#{directory}/tick"
      }
      _, errors, status = Open3.capture3(environment, 'sh', Rails.root.join('entrypoint.sh').to_s, chdir: directory)
      expect(status.success?).to eq(true), errors
      File.readlines("#{directory}/calls", chomp: true)
    end
  end

  it 'resets at startup and again after a 24-hour interval when demo mode is enabled' do
    calls = run_startup('true')
    expect(calls.count('exec rails demo:reset')).to eq(2)
    expect(calls.index('exec rails demo:reset')).to be < calls.index('exec rails s -p 3000 -b 0.0.0.0')
    expect(calls).to include('exec rails db:migrate', 'sleep 86400')
  end

  it 'does not reset or schedule deletion during normal startup' do
    calls = run_startup('false')
    expect(calls).to include('exec rails db:migrate', 'exec rails s -p 3000 -b 0.0.0.0')
    expect(calls).not_to include('exec rails demo:reset', 'sleep 86400')
  end
end
