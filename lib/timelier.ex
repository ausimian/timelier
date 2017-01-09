defmodule Timelier do

  @moduledoc """
  A cron-style scheduling library for Elixir.

  ## Overview
  Timelier is a _cron_ style scheduling application for Elixir. It will
  match a list of time 'patterns' against the current time and start any
  tasks associated with each matching pattern.

  By default, the set of scheduled tasks is sourced from the `crontab`
  environment variable within the `Timelier` application or `[]` if not
  present. For example, the following snippet from config.exs defines a
  task that runs every 15 minutes and dumps a message via
  `:error_logger.info_msg/1`.

      config :timelier,
             crontab: [{{[0,15,30,45],:any,:any,:any,:any}, {:error_logger,:info_msg,['Hello world.~n']}}]

  ## Crontab format
  The format of the crontab is a list of tuple pairs, where the first
  tuple describes the time pattern and the second specifies the task to be
  invoked when the pattern matches the current time.

  The task is 3-tuple of {mod, func, args} and is run by a temporary
  GenServer under a simple-one-for-one strategy. The return result of
  applying this triple is ignored, but any crashes will generate a crash
  report.

  The time pattern is 5-tuple specifying the minute, hour, day,
  weekday, and month. Each element may be:

  - A single specific value (see the types for the valid ranges).
  - Wildcarded with `:any`, which will always match.
  - Described as a list, in which case the elements describe the set of valid values.

  In addition, the `day` and `weekday` elements support some special
  ranges:

  - The `day` element may take negative values in the range -31 .. -1,
    where -1 indicates the last day of the month, -2 the penultimate day
    of the month and so on.
  - The `weekday` element may take negative values in the range -7 ..
    -1 where -1 means 'the last Monday of the month' and -7 means 'the
    last Sunday of the month'.

  ### Time evaluation
  Every minute, the application converts the current timestamp (from
  `:erlang.timestamp/0`) into an internal datetime representation that may
  either be in UTC or local time, before matching against the crontab
  entries.

  This representation is controlled by the `timezone` environment
  variable, which may either be `:utc` or `:local`. The default, if
  unspecified, is `:local`.

  ### Alternative Providers
  To use an alternative source of scheduled tasks,
  specify the provider environment variable and ensure that the
  specified callback returns a tuple of the type `{:ok,
  Timelier.crontab}`, e.g.

      config :timelier,
             provider: {mod, func, [arg1, arg2 ...]}

  """

  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(Timelier.Task.Supervisor, []),
      worker(Timelier.Server, []),
      worker(Timelier.Timer, [])
      # Starts a worker by calling: Timelier.Worker.start_link(arg1, arg2, arg3)

      # worker(Timelier.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :rest_for_one, name: Timelier.Supervisor]
    Supervisor.start_link(children, opts)
  end


  @typedoc """
  Valid range for the minute element.
  """
  @type minute()  :: 0..59

  @typedoc """
  Valid range for the hour element.
  """
  @type hour()    :: 0..23

  @typedoc """
  Valid ranges for the day of the month element.

  Negative values indicate days from the end of the month i.e. -1 means
  last day of the month, -2 means the penultimate day of the month.
  """
  @type day()     :: -31..-1 | 1..31

  @typedoc """
  Valid ranges for the day of the week element.

  Positive values start at 1 (Monday) and run through 7 (Sunday).
  Negative values have a different meaning. -1 means 'the last Monday of
  the month' and -7 means 'the last Sunday of the month.'
  """
  @type weekday() ::  -7..-1 | 1..7

  @typedoc """
  Valid range for the month element.
  """
  @type month()   :: 1..12

  @typedoc """
  Valid range for the year element.

  Notwithstanding the BEAM's reputation for reliability and longevity,
  10000 is probably enough.
  """
  @type year()    :: 1970..10000


  @typedoc """
  Represents a time pattern.

  A 5-tuple whose elements represent the minute, hour, day, weekday and
  month. Each element may a distinct value, a list of alternatives or a
  wildcard.
  """
  @type pattern() :: { minute()  | [minute()]  | :any,
                       hour()    | [hour()]    | :any,
                       day()     | [day()]     | :any,
                       weekday() | [weekday()] | :any,
                       month()   | [month()]   | :any }

  @typedoc """
  Represents actual time.
  """
  @type time()    :: { minute(),
                       hour(),
                       day(),
                       weekday(),
                       month(),
                       year()}

  @typedoc """
  Represents the type of a task.

  A 3-tuple holding the module, function and any arguments to be applied.
  """
  @type task()    :: { atom(), atom(), [any()] }

  @typedoc """
  Represents an individual entry in the crontab.

  Composed of a pattern and a task. When the pattern matches the time,
  the task is started.
  """
  @type entry()   :: { pattern(), task() }

  @typedoc """
  A list of crontab entries.
  """
  @type crontab() :: [entry()]

  @doc """
  Updates the current crontab configuration.

  If the crontab is invalid, this function will crash.
  """
  @spec update(crontab :: crontab) :: :ok
  def update(crontab), do: Timelier.Server.update(crontab)

  @doc """
  Check the current crontab for any pending tasks.

  This function will translate the current timestamp into either utc or
  local time and check the crontab for matches on the values.
  """
  @spec check() :: :ok
  def check() do
    tz   = Application.get_env(Timelier, :timezone, :local)
    func = case tz do
             :utc   -> :now_to_universal_time
             :local -> :now_to_local_time
           end
    {date, time} = apply(:calendar, func, [:erlang.timestamp()])

    weekday = :calendar.day_of_the_week(date)

    {yr, mon, day} = date
    {hr, min, _}   = time

    Timelier.Server.check({min, hr, day, weekday, mon, yr})
  end
end
