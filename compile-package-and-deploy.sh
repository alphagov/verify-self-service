#!/usr/bin/env bash
set -e

rm -rf out/
mkdir -p out
docker build . -f lambda.Dockerfile -t rails-lambda-build
docker create --name rails-lambda-build-container rails-lambda-build 
docker cp rails-lambda-build-container:/var/task out
docker rm rails-lambda-build-container
cd out/task
./package-and-deploy.sh
