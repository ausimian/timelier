defmodule TimelierTest do
  use ExUnit.Case
  use Quixir
  doctest Timelier

  test "Updated crontabs must be valid" do
    ptest crontab: crontab() do
      :ok = Timelier.update(crontab)
    end
  end

  test "A match on a date and time runs the task" do
    ptest crontab: nonempty_crontab(), entry: int(min: 0, max: length(^crontab) - 1) do
      :ok     = Timelier.update(crontab)
      {pt, _} = Enum.at(crontab, entry)
      time    = pattern_to_time(pt)
      :ok     = Timelier.Server.check(time)

      assert_receive :triggered, 100
    end
  end

  defp crontab,          do: list(tuple(like: {pattern(), value(action())}))
  defp nonempty_crontab, do: list(of: tuple(like: {pattern(), value(action())}), min: 1)

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

  defp action,  do: {Kernel, :send, [self(), :triggered]}

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
