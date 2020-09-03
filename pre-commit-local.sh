#!/usr/bin/env bash
docker build . -f test.Dockerfile -t verify-selfservice-test

docker container run -t --rm \
-v $(pwd):/verify-self-service \
-w /verify-self-service verify-selfservice-test \
bash -c "/etc/init.d/postgresql start && ./pre-commit.sh"
