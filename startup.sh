#!/bin/bash

RUN_IN_DOCKER=false

show_help() {
  cat << EOF
Options:
  -d , --docker   Run using docker
EOF
}

while [ "$1" != "" ]; do
  case $1 in
      -d | --docker)    shift
                        RUN_IN_DOCKER=true
                        ;;
      *)                echo -e "Unknown option $1...\n"
                        show_help
                        exit 1
  esac
  shift
done

if [[ $RUN_IN_DOCKER == 'false' ]]; then
  while true; do
      read -rp "Run using Docker? [y/n] " p
      case $p in
          y|Y|yes)    RUN_IN_DOCKER=true
                      break
                      ;;
          n|N|no)     break
                      ;;
          x|X|exit)   exit 0
                      ;;
          *)          echo "Unknown option."
                      ;;
    esac
  done
fi

if [[ $RUN_IN_DOCKER == 'true' ]]; then
  docker build . -f run.Dockerfile -t verify-self-service
  docker run --rm -p 8080:8080 -it verify-self-service
else
  set -e
  bundle check || bundle install
  yarn check || yarn install
  bin/rails s
fi
