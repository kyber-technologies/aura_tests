# Aura Testing Suite

**Testing suite for the Aura gRPC service**

## Introduction

Due to the complex nature of the Aura gRPC service,
this test suite was created in order to test service functionality.

## Setup

In order for the tests to even work, you need a running Elysium gRPC Service with the `testing` feature.

You can do this by running `cargo run --features testing` inside
the [aura_server](https://github.com/kyber-technologies/aura_server) repository.

## Running Tests

You can run tests via the `run.bat` or `run.sh` scripts and specify arguments.

The testing suite contains multiple testing groups you can run by specifying the group name as the first argument.

Run `run list` for a list of groups and `run user` for example to run the user test group.
