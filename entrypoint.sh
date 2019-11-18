#!/bin/bash
set -e
bundle exec rake assets:precompile
bundle exec puma -p 8080 -b tcp://0.0.0.0