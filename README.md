# Timelier

[![Hex](https://img.shields.io/hexpm/v/timelier.svg)](https://hex.pm/packages/timelier) [![Build Status](https://travis-ci.org/ausimian/timelier.svg?branch=master)](https://travis-ci.org/ausimian/timelier) [![Coverage Status](https://coveralls.io/repos/github/ausimian/timelier/badge.svg?branch=master)](https://coveralls.io/github/ausimian/timelier?branch=master)

Timelier is a _cron_ style scheduling application for Elixir. It will match a list of time
'patterns' against the current time and start any tasks associated with each matching pattern.

## Installation

  1. Add `timelier` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:timelier, "~> 0.9.2"}]
    end
    ```

  2. To ensure `timelier` can successfully start tasks defined in your application (or
     its dependencies), add it as an [included application](http://erlang.org/doc/design_principles/included_applications.html):

    ```elixir
    def application do
      [included_applications: [:timelier]]
    end
    ```
    
    and append it's root supervisor to the list of children that your own top-level
    supervisor starts, e.g.
    
    ```elixir
    def start(_type, _args) do
      import Supervisor.Spec, warn: false

      # Define workers and child supervisors to be supervised
      children = [
        worker(YourApp.YourWorker, []),
        # Other children in your supervision tree...

        supervisor(Timelier.Supervisor, []) # Add timelier's top-level supervisor
      ]

      opts = [strategy: :one_for_one, name: YourApp.Supervisor]
      Supervisor.start_link(children, opts)
    end
    ```
    
## Configuration

There are three configuration variables that may be specified in the `:timelier` application:

  * `crontab`: The list of crontab entries - see below for a discussion of the format. If not
      specified, defaults to the empty list.
  * `timezone`: Either `:local` or `:utc`. This determines how the current time
     is matched against the crontab entries. If not specified, defaults to `:local`
  * `provider`: Allows the source of crontab configuration to be overridden. See the hex docs
     for more information.

### Crontab entry format.

Each entry in the crontab list is a 2-tuple of `{pattern, task}`.

  * The pattern is a 5-tuple of the form `{minute, hour, day, day-of-week, month}`. Both wildcards
    and alternates may be specified for each entry. See the hex docs for more detail.
  * The task is a 3-tuple of {module, function, args} as would be passed to `Kernel.apply/3`.
