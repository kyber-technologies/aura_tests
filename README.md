# Aura Testing Suite

An extended testing suite for the Aura network.

## Prerequisites

You will need [Dart](https://dart.dev) for running the tests and a running Aura Server,
as well as a running mailhog instance and a PostgreSQL database.

Note that the server must be in testing mode (run via `--features testing` or `dev/run-testing.sh`).

## Usage

You can use the `test.sh` or `test.bat` scripts to run tests.

**Commands:**

- `help` - To get help about the CLI.
- `list` - To list all available tests.
- `all` - To run all tests.
- `<test>` - To run a specific test.

The testing suite will automatically collect results and method coverage.
