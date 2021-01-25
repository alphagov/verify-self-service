#!/bin/bash

while true; do
    read -p "Run using Docker? [y/n] " p
    case $p in
        y|Y|yes)    docker build . -f run.Dockerfile -t verify-self-service
                    docker run --rm -p 8080:8080 -it verify-self-service
                    break
                    ;;
        n|N|no)     set -e
                    bundle check || bundle install
                    yarn check || yarn install
                    bin/rails s
                    break
                    ;;
        x|X|exit)   exit 0
                    ;;
        *)          echo "Unknown option."
                    ;;
    esac
done
