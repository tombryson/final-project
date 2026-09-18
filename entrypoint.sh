#!/bin/sh
set -e

sleep 20

if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

bundle exec rails db:migrate

if [ "${DEMO_MODE:-false}" = "true" ]; then
  bundle exec rails demo:reset
  (
    while sleep 86400; do
      bundle exec rails demo:reset || echo 'Demo reset failed. Check the server logs.' >&2
    done
  ) &
fi

exec bundle exec rails s -p 3000 -b '0.0.0.0'
