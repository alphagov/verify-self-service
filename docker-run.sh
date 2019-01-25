#!/usr/bin/env bash

cd $(dirname "${BASH_SOURCE[0]}")

docker build -t verify-self-service:latest -f Dockerfile . 2>&1
echo "verify-self-service:latest"
