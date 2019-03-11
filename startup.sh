#!/bin/bash
set -e
bundle check || bundle install

yarn check || yarn install

bin/rails s
