ARG RUBY_VERSION
ARG RUBY_PLATFORM
FROM ${RUBY_PLATFORM}:${RUBY_VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends git

WORKDIR /usr/src/app

COPY lib/jsonb_accessor/version.rb ./lib/jsonb_accessor/version.rb
COPY jsonb_accessor.gemspec Gemfile ./
# RUN bundle install
COPY . ./
