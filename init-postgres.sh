#!/bin/bash

# Change to the postgres user
su - postgres -c "createuser -s root"

# Initialize the database
su - postgres -c "initdb /var/lib/postgresql/data"

echo "host all all 127.0.0.1/32 scram-sha-256" >> /var/lib/postgresql/data/pg_hba.conf
echo "listen_addresses='127.0.0.1'" >> /var/lib/postgresql/data/postgresql.conf

# Start PostgreSQL server
su - postgres -c "/usr/lib/postgresql/14/bin/postgres -D /var/lib/postgresql/data"
