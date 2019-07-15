FROM ruby:2.6.2

ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock

EXPOSE 3000

ENV RAILS_LOG_TO_STDOUT true

RUN bundle install

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && apt-get install -y nodejs

ADD . /verify-self-service/

WORKDIR /verify-self-service

CMD bundle exec puma -p 3000


