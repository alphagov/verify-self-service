FROM ruby:2.6.5

ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock

RUN bundle install

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && apt-get install -y nodejs

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
 && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
 && apt-get update -qq \
 && apt-get install -y yarn

RUN apt-get install -y firefox-esr
RUN apt-get install -y postgresql-9.6

USER postgres

RUN  /etc/init.d/postgresql start &&\
    psql --command "CREATE DATABASE vss_test;" -U postgres &&\
    sed -i 's/local   all             postgres                                peer/local   all             postgres                                trust/g' /etc/postgresql/9.6/main/pg_hba.conf

USER root
