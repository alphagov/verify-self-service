FROM ghcr.io/alphagov/verify/ruby:2.6.6

ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock

# We're hoping adding this stops the pipeline breaking
# see https://github.com/sass/sassc-ruby/issues/146
RUN bundle config --local build.sassc --disable-march-tune-native \
    && bundle install \
    && curl -sL https://deb.nodesource.com/setup_10.x | bash - && apt-get install -y nodejs \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update -qq \
    && apt-get install -y yarn \
    && apt-get install -y postgresql-11

USER postgres

RUN  /etc/init.d/postgresql start &&\
  psql --command "CREATE DATABASE vss_development;" -U postgres &&\
  psql --command "CREATE USER root WITH SUPERUSER PASSWORD 'docker';" &&\
  sed -i 's/local   all             root                                peer/local   all             root                                trust/g' /etc/postgresql/11/main/pg_hba.conf

USER root

ADD . /verify-self-service/

WORKDIR /verify-self-service
RUN /etc/init.d/postgresql start && rails db:migrate RAILS_ENV=development

RUN bundle check || bundle install
RUN yarn check || yarn install
RUN bundle exec rake assets:precompile assets:undigest_assets

CMD /etc/init.d/postgresql start && bundle exec puma -p 8080
