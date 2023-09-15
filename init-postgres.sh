#!/bin/bash

# Change to the postgres user
su - postgres -c "createuser -s root"

# Initialize the database
su - postgres -c "initdb /var/lib/postgresql/data"

# Update PostgreSQL configuration to accept connections from any IP address
echo "host all all 0.0.0.0/0 trust" >> /var/lib/postgresql/data/pg_hba.conf
echo "listen_addresses='*'" >> /var/lib/postgresql/data/postgresql.conf

# Start PostgreSQL server
su - postgres -c "/usr/lib/postgresql/14/bin/postgres -D /var/lib/postgresql/data"