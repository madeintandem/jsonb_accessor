ARG RUBY_VERSION=latest
FROM ruby:${RUBY_VERSION}

WORKDIR /usr/src/app

RUN mkdir -p lib/jsonb_accessor
COPY lib/jsonb_accessor/version.rb ./lib/jsonb_accessor/
COPY *.gemspec Gemfile* ./

RUN bundle install

COPY . .
