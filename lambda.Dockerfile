FROM lambci/lambda:build-ruby2.5
RUN yum -y install postgresql-devel postgresql-libs
RUN curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
RUN curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
RUN yum check-update || :
RUN yum -y install nodejs
RUN yum -y install yarn
COPY . /var/task
RUN (cd /var/task && yarn install)
RUN (cd /var/task && bundle install --deployment --without test development)
ENV SECRET_KEY_BASE noop
RUN (cd /var/task && RAILS_ENV=production bin/rails assets:precompile)
RUN cp /usr/lib64/libpq.so.5 /var/task/lib

CMD bash
