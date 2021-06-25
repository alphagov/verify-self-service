#!/usr/bin/env bash
docker build . -f test.Dockerfile -t verify-self-service-test

docker container run -t --rm \
-v "$(pwd)":/verify-self-service \
-w /verify-self-service verify-self-service-test \
bash -c "/etc/init.d/postgresql start && ./pre-commit.sh"
