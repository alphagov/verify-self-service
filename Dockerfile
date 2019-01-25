FROM ruby:2.6.0

ADD Gemfile Gemfile

RUN bundle install

RUN apt-get update -qq && apt-get install -y nodejs

ADD . /verify-self-service/

WORKDIR /verify-self-service

# Puma needs these dockerignored dirs to write to
RUN mkdir -p log tmp

CMD bundle exec rspec
