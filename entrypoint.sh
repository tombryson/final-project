#!/bin/sh
set -e

sleep 20

if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

bundle exec rake db:migrate 2>/dev/null || bundle exec rake db:setup

bundle exec rails db:seed

exec bundle exec rails s -p 3000 -b '0.0.0.0'