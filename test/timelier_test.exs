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

  defp crontab,       do: list(of: crontab_entry())
  defp crontab_entry, do: tuple(like: {pattern(), action()})

  defp pattern do
    tuple(like: {wildcard(minute()),
                 wildcard(hour()),
                 wildcard(day()),
                 wildcard(weekday()),
                 wildcard(month())})
  end

  defp minute,  do: int(min: 0, max: 59)
  defp hour,    do: int(min: 0, max: 23)
  defp day,     do: int(min: 1, max: 31)
  defp weekday, do: int(min: 1, max:  7)
  defp month,   do: int(min: 1, max: 12)

  defp wildcard(generator), do: choose(from: [generator, value(:any)])

  defp action, do: tuple(like: {value(Kernel), value(:send), action_args()})
  defp action_args, do: list(of: seq(of: [value(self()), any()]), min: 2, max: 2)

  defp pattern_to_time({minute, hour, day, weekday, month}) do
    { unwildcard(minute, minute()),
      unwildcard(hour, hour()),
      unwildcard(day, day()),
      unwildcard(weekday, weekday()),
      unwildcard(month, month()),
      2017}
  end

  defp unwildcard(:any, g),   do: Pollution.Generator.as_stream(g) |> Enum.at(0)
  defp unwildcard(value, _g), do: value
end
