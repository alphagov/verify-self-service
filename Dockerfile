FROM ruby:2.6.0

ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock

RUN bundle install


RUN apt-get update -qq && apt-get install -y nodejs

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get install -y yarn

RUN apt-get install -y firefox-esr

# Puma needs these dockerignored dirs to write to
RUN mkdir -p log tmp
