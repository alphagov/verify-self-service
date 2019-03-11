# Verify Self-service platform

[![Build Status](https://travis-ci.org/alphagov/verify-self-service.svg?branch=master)](https://travis-ci.org/alphagov/verify-self-service)

A Ruby on Rails application for the Verify self-service configuration management
platform. It is currently a work in progress.

## Technical Documentation

Architecture Decision Records can be found in [`doc/adr/`](doc/adr/).

The application is being developed using the principle of Event Sourcing. Please
see [doc/adr/0002-use-event-sourcing.md](doc/adr/0002-use-event-sourcing.md) to
understand why we made that decision and how we are doing it.

### Running the application

You can start the application with:

`./startup.sh`

### Running the tests

`./pre-commit.sh` will run the tests.

You can use `bundle exec rspec $PATH_TO_SPEC` to run individual spec files.

## Licence

[MIT License](LICENCE)

## Code of Conduct
This project is developed under the [Alphagov Code of Conduct](https://github.com/alphagov/code-of-conduct)
