# Verify Self Service Platform

[![Build Status](https://travis-ci.org/alphagov/verify-self-service.svg?branch=master)](https://travis-ci.org/alphagov/verify-self-service)

A Ruby on Rails application for the Verify self-service configuration management
platform.

Currently provides functionality to:
* rotate (upload) encryption and signing certificates for the connected services (for both production and integration environments)
* publish the certificates to S3 bucket which is then consumed by Verify Hub
* notify users of expiring certificates (30, 14 and 3 days in advance)
* authenticate users (using AWS Cognito) with enforced MFA
* user management for team admins/user managers (invite, delete, reset passwords)

## Technical Documentation

Architecture Decision Records can be found in [`doc/adr/`](doc/adr/).

The application is being developed using the principle of Event Sourcing. Please
see [doc/adr/0002-use-event-sourcing.md](doc/adr/0002-use-event-sourcing.md) to
understand why we made that decision and how we are doing it.

Further information on how to support the appplication can be found in the 
[Verify Team Manual](https://verify-team-manual.cloudapps.digital/documentation/support/#verify-self-service).

### Running the application

You can start the application with:

`./startup.sh`

### Running the tests

`./pre-commit.sh` will run the tests.

You can use `bundle exec rspec $PATH_TO_SPEC` to run individual spec files.

### Linting

This is done using Rubocop and the [govuk-lint](https://github.com/alphagov/govuk-lint) rules. It runs with the pre-commit but you can also run it manually:

`bundle exec rubocop`

To automagically fix any issues use the `-a` flag:

`bundle exec rubocop -a`

### Integrity checker when on-boarding a service

The `/tools` directory contains a script `./check.rb` which allows us to check whether a service
has been on-boarded correctly to the self-service app. There are a few steps required:

1. Fully on-board the service (or MSA) to self-service, as per the [team manual instructions](https://verify-team-manual.cloudapps.digital/documentation/support/self-service/onboard-new-service.html)
2. Make sure the [verify-hub-federation-config]() repository is on master and up-to-date
3. Login to AWS using the gds-cli
    - `gds aws verify-prod-a -e` for the production environment
    - `gds aws verify-integration-a -e` for the integration environment
4. Run the script using the environment and entityId you wish to check for

    `./check.rb <prod | integration> <entityId> [--msa optional]`

    For example:

    `./check.rb prod http://prod-entity-id`

The script will output whether the hub-fed-config is matching the config which self-service is publishing.
This script can only be used while the certs are still in the hub-fed-config (i.e. before they were removed after the on-boarding)

## Licence

[MIT License](LICENCE)

## Code of Conduct
This project is developed under the [Alphagov Code of Conduct](https://github.com/alphagov/code-of-conduct)
