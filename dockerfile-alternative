# Use the official Ruby base image
FROM amd64/ruby:2.7.6

# Install netcat
RUN apt-get update && apt-get install -y netcat

# Add Node.js to the repository
RUN apt-get update -qq && apt-get install -y curl
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -

# Install Node.js and Yarn
RUN apt-get install -y nodejs

# Install PostgreSQL
RUN apt-get install -y postgresql postgresql-contrib

# Set the working directory
WORKDIR /app

# Copy the Gemfile and Gemfile.lock into the image
COPY Gemfile Gemfile.lock ./

# Install bundler and bundle the gems
RUN gem install bundler && bundle install

# Copy the rest of the application into the image
COPY . .

# Copy the entrypoint script into the image and make it executable
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# Expose the port the app will run on
EXPOSE 3000

# Copy PostgreSQL init script
COPY init-postgres.sh /init-postgres.sh

# Start the PostgreSQL server and Rails server
CMD /init-postgres.sh & bundle exec rails server -b 0.0.0.0 -p 3000

# Start the Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
