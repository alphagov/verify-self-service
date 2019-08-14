#!/bin/bash
set -eu

if [[ ! $(git secrets 2>/dev/null) ]]; then
  echo "⚠️ This repository should be checked against leaked AWS credentials ⚠️"
  echo "We highly recommend you run the following:"
  echo "   brew install git-secrets"
  echo "then to set up the git-secrets to run on each commit:"
  echo "   git secrets --install"
  echo "   git secrets --register-aws"
  echo " === !!! !!! !!! === "
  exit 1
else
  for hook in .git/hooks/commit-msg .git/hooks/pre-commit .git/hooks/prepare-commit-msg; do
    if ! grep -q "git secrets" $hook; then
      git secrets --install -f
    fi
  done
  git secrets --register-aws
fi

if ! command -v pre-commit 2>/dev/null; then
  echo "This repository has configuration for running pre-commit automatically"
  echo "via the pre-commit.com tooling. We highly recommend you run the following:"
  echo "   brew install pre-commit"
  echo "then to set up pre-commit to run on pre-push:"
  echo "   pre-commit install --hook-type pre-push"
else
  if [ ! -f .git/hooks/pre-push ]; then
    pre-commit install --hook-type pre-push
  fi
fi

bundle exec govuk-lint-ruby app lib

bundle check || bundle install

echo -e "[RSPEC] --> init (wait a second)"

FAILS=`bundle exec rake | grep -E '(\d*) failure(s?)' -o | awk '{print $1}'`

if [ $FAILS -ne 0 ]; then
  echo -e "[RSPEC] --> ✋ Can't commit! You've broken $FAILS tests!!!"
  exit 1
else
  echo -e "[RSPEC] --> 👍 Commit approved."
  exit 0
fi
