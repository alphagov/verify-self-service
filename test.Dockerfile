ARG base_image=ruby:2.6.6
FROM ${base_image}

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
    && apt-get install -y firefox-esr \
    && apt-get install -y postgresql-11

USER postgres

RUN  /etc/init.d/postgresql start &&\
  psql --command "CREATE DATABASE vss_test;" -U postgres &&\
  sed -i 's/local   all             postgres                                peer/local   all             postgres                                trust/g' /etc/postgresql/11/main/pg_hba.conf

USER root
