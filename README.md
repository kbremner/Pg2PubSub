# Pg2pubsub [![Build Status](https://semaphoreci.com/api/v1/kbremner/pg2pubsub/branches/master/badge.svg)](https://semaphoreci.com/kbremner/pg2pubsub)

Implementation of Pub/Sub communication between processes, local and remote, using [PG2](http://erlang.org/doc/man/pg2.html).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add pg2pubsub to your list of dependencies in `mix.exs`:

        def deps do
          [{:pg2pubsub, "~> 0.1.0"}]
        end

  2. Ensure pg2pubsub is started before your application:

        def application do
          [applications: [:pg2pubsub]]
        end
