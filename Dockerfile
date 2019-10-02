FROM ruby:2.6.5

ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock

EXPOSE 8080

ENV RAILS_LOG_TO_STDOUT true

ENV RAILS_SERVE_STATIC_FILES true

RUN bundle install

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && apt-get install -y nodejs

RUN npm install yarn -g

ADD . /verify-self-service/

WORKDIR /verify-self-service

RUN bundle exec rake assets:precompile assets:undigest_assets

CMD bundle exec puma -p 8080


