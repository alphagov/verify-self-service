ARG base_image=ruby:2.6.6
FROM ${base_image}

ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock

EXPOSE 8080

ENV RAILS_LOG_TO_STDOUT true

ENV RAILS_SERVE_STATIC_FILES true

# We're hoping adding this stops the pipeline breaking
# see https://github.com/sass/sassc-ruby/issues/146
RUN bundle config --local build.sassc --disable-march-tune-native
RUN bundle install

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && apt-get install -y nodejs

ADD . /verify-self-service/

WORKDIR /verify-self-service

RUN bundle exec rake assets:precompile assets:undigest_assets

CMD bundle exec puma -p 8080


