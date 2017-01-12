# Timelier

[![Build Status](https://travis-ci.org/ausimian/timelier.svg?branch=master)](https://travis-ci.org/ausimian/timelier) [![Coverage Status](https://coveralls.io/repos/github/ausimian/timelier/badge.svg?branch=master)](https://coveralls.io/github/ausimian/timelier?branch=master) [![Ebert](https://ebertapp.io/github/ausimian/timelier.svg)](https://ebertapp.io/github/ausimian/timelier)

Timelier is a _cron_ style scheduling application for Elixir. It will
match a list of time 'patterns' against the current time and start any
tasks associated with each matching pattern.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `timelier` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:timelier, "~> 0.1.0"}]
    end
    ```

  2. Ensure `timelier` is started before your application:

    ```elixir
    def application do
      [applications: [:timelier]]
    end
    ```

