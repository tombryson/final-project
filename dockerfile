# Use the official Ruby base image
FROM ruby:2.7.6

# Install dependencies
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

# Set the working directory
WORKDIR /app

# Copy the Gemfile and Gemfile.lock into the image
COPY Gemfile* ./

# Install bundler and bundle the gems
RUN gem install bundler && bundle install

# Copy the rest of the application into the image
COPY . .

# Expose the port the app will run on
EXPOSE 3000

# Start the Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]