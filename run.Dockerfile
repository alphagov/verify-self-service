FROM ruby:2.6.6

ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock

ADD . /verify-self-service/

# We're hoping adding this stops the pipeline breaking
# see https://github.com/sass/sassc-ruby/issues/146
RUN bundle config --local build.sassc --disable-march-tune-native \
    && bundle config force_ruby_platform true \
    && bundle install \
    && wget https://dl.yarnpkg.com/debian/pubkey.gpg \
    && curl -sL https://deb.nodesource.com/setup_14.x | bash - && apt-get install -y nodejs \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update -qq \
    && apt-get upgrade -y \
    && apt-get install -y yarn \
    && apt-get install -y postgresql-11 \
    && rm -rf /var/lib/apt/lists/* \
    && apt clean \
    && rm pubkey.gpg

RUN chown -R postgres verify-self-service/

USER postgres

RUN  /etc/init.d/postgresql start &&\
  psql --command "CREATE DATABASE vss_development;" -U postgres &&\
  psql --command "CREATE USER root WITH SUPERUSER PASSWORD 'docker';" &&\
  sed -i 's/local   all             root                                peer/local   all             root                                trust/g' /etc/postgresql/11/main/pg_hba.conf

WORKDIR /verify-self-service
RUN /etc/init.d/postgresql start && rails db:migrate RAILS_ENV=development

RUN bundle check || bundle install
RUN yarn check || yarn install
RUN bundle exec rake assets:precompile assets:undigest_assets

CMD /etc/init.d/postgresql start && bundle exec puma -p 8080
