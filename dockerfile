# Use the official Ruby base image
FROM ruby:2.7.6-bullseye

# Set the working directory
WORKDIR /app

# Copy the Gemfile and Gemfile.lock into the image
COPY Gemfile* ./

# Install bundler and bundle the gems
RUN gem install bundler -v 2.2.22 && bundle _2.2.22_ install

# Copy the rest of the application into the image
COPY . .
RUN mkdir -p tmp/pids log && chmod +x entrypoint.sh

# Expose the port the app will run on
EXPOSE 3000

# Start the Rails server
CMD ["./entrypoint.sh"]
