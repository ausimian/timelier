defmodule TimelierTest do
  use ExUnit.Case
  use Quixir
  doctest Timelier

  test "Updated crontabs must be valid" do
    ptest crontab: crontab() do
      assert :ok == Timelier.update(crontab)
    end
  end

  test "A match on a date and time runs the task" do
    ptest entry: crontab_entry(), rpt: int(min: 1, max: 2) do
      :ok  = Timelier.update(List.duplicate(entry, rpt))
      {pattern, {_,_,[_,msg]}} = entry
      time = pattern_to_time(pattern)
      :ok  = Timelier.Server.check(time)

      for _ <- 1..rpt, do: assert_receive ^msg, 100
    end
  end

  test "Lists provide alternate matches" do
    ptest entry: crontab_entry_alts(), rpt: int(min: 1, max: 2) do
      :ok  = Timelier.update(List.duplicate(entry, rpt))
      {pattern, {_,_,[_,msg]}} = entry
      time = alt_pattern_to_time(pattern)
      :ok  = Timelier.Server.check(time)

      for _ <- 1..rpt, do: assert_receive ^msg, 100
    end
  end

  test "Negative day of month patterns" do
    ptest d: int(min: -31, max: -1), m: month(), y: year() do
      ldom = :calendar.last_day_of_the_month(y,m)
      dneg = max(d, -ldom)
      dom  = max(1, ldom + 1 + dneg)
      dow  = :calendar.day_of_the_week(y,m,dom)
      :ok  = Timelier.update([{{:any,:any,dneg,:any,m},{Kernel,:send,[self(), :fired]}}])
      time = {0,10,dom,dow,m,y}
      :ok  = Timelier.Server.check(time)

      assert_receive :fired, 100
    end
  end

  test "Negative day of week patterns" do
    ptest d: int(min: -7, max: -1), m: month(), y: year() do
      ldom = :calendar.last_day_of_the_month(y,m)
      ldow = last_weekday_of_month(y,m,ldom,-d)
      :ok  = Timelier.update([{{:any,:any,:any,d,m},{Kernel,:send,[self(), :fired]}}])
      time = {0,10,ldow,-d,m,y}
      :ok  = Timelier.Server.check(time)

      assert_receive :fired, 100
    end
  end

  test "Timer fires and invokes server." do
    # Insert a crontab that always matches
    :ok = Timelier.update([{{:any,:any,:any,:any,:any},{Kernel,:send,[self(), :fired]}}])
    # Kill the timer process so that it automatically restarts and starts checking
    Process.exit(Process.whereis(Timelier.Timer), :kill)
    # Check the task is started
    assert_receive(:fired, 100)
  end

  defp last_weekday_of_month(y,m,d,wd) do
    case :calendar.day_of_the_week(y,m,d) do
      ^wd -> d
      _   -> last_weekday_of_month(y,m,d-1,wd)
    end
  end

  defp crontab,       do: list(of: crontab_entry())
  defp crontab_entry, do: tuple(like: {pattern(), action()})
  defp crontab_entry_alts, do: tuple(like: {alt_pattern(), action()})

  defp pattern do
    tuple(like: {wildcard(minute()),
                 wildcard(hour()),
                 wildcard(day()),
                 wildcard(weekday()),
                 wildcard(month())})
  end

  defp alt_pattern do
    tuple(like: {alternate(minute()),
                 alternate(hour()),
                 alternate(day()),
                 alternate(weekday()),
                 alternate(month())})
  end

  defp minute,  do: int(min: 0, max: 59)
  defp hour,    do: int(min: 0, max: 23)
  defp day,     do: int(min: 1, max: 31)
  defp weekday, do: int(min: 1, max:  7)
  defp month,   do: int(min: 1, max: 12)
  defp year,    do: int(min: 2017, max: 10000)

  defp wildcard(generator),  do: choose(from: [generator, value(:any)])
  defp alternate(generator), do: list(of: generator, min: 1, max: 3)

  defp action, do: tuple(like: {value(Kernel), value(:send), action_args()})
  defp action_args, do: list(of: seq(of: [value(self()), any()]), min: 2, max: 2)

  defp pattern_to_time({minute, hour, day, weekday, month}) do
    { unwildcard(minute, minute()),
      unwildcard(hour, hour()),
      unwildcard(day, day()),
      unwildcard(weekday, weekday()),
      unwildcard(month, month()),
      unwildcard(:any, year())}
  end

  defp alt_pattern_to_time({minutes, hours, days, weekdays, months}) do
    { List.last(minutes),
      List.last(hours),
      List.last(days),
      List.last(weekdays),
      List.last(months),
      unwildcard(:any, year())}
  end

  defp unwildcard(:any, g),   do: Pollution.Generator.as_stream(g) |> Enum.at(0)
  defp unwildcard(value, _g), do: value
end
