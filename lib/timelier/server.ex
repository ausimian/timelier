defmodule Timelier.Server do
  use GenServer

  @moduledoc """
  This module defines a `GenServer` that maintains the crontab as its
  state and will check a supplied time against this state, starting any
  tasks whose time pattern matches.
  """

  @name __MODULE__

  @spec start_link() :: GenServer.on_start
  def start_link(), do: GenServer.start_link(__MODULE__, [], name: @name)

  @spec update(Timelier.crontab) :: :ok
  def update(crontab) when is_list(crontab) do
    true = is_valid?(crontab)
    GenServer.cast(@name, {:update, crontab})
  end

  @spec check(Timelier.time) :: :ok
  def check(time) do
    GenServer.cast(@name, {:check, time})
  end

  def init([]), do: {:ok, []}

  def handle_cast({:update, crontab}, _), do: {:noreply, crontab}
  def handle_cast({:check, time}, crontab) do
    check(time, crontab)
    {:noreply, crontab}
  end

  defp check(time, crontab) do
    for {pattern, task} <- crontab, is_match?(time, pattern) do
      _ = Timelier.Task.Supervisor.start_task(task)
    end
    :ok
  end

  defp is_match?(time, pattern) do
    {mi, hr, day, dow, month, year} = time
    {pmi, phr, pday, pdow, pmonth}  = pattern

    is_part_match?(:minute, pmi, mi) and
    is_part_match?(:hour, phr, hr) and
    is_part_match?({:day, month, year}, pday, day) and
    is_part_match?({:weekday, day, month, year}, pdow, dow) and
    is_part_match?(:month, pmonth, month)
  end

  defp is_part_match?(part, [pattern|rest], val) do
    is_part_match?(part, pattern, val) or is_part_match?(part, rest, val)
  end

  defp is_part_match?({:day, month, year}, pattern, val)
  when is_integer(pattern) and pattern < 0 do
    last_day = :calendar.last_day_of_the_month(year, month)
    pattern + last_day + 1 === val
  end

  defp is_part_match?({:weekday, day, month, year}, pattern, val)
  when is_integer(pattern) and pattern < 0 do
    last_day = :calendar.last_day_of_the_month(year, month)
    (last_day - day) < 7 and abs(pattern) === val
  end

  defp is_part_match?(_, pattern, val) do
    pattern === :any or pattern === val
  end

  defp is_valid?(crontab) do
    :lists.all(fn(e) -> is_valid_entry?(e) end, crontab)
  end

  defp is_valid_entry?({{pmi, pho, pday, pdow, pmo}, _}) do
    is_valid_elem?(:minute, pmi) and
    is_valid_elem?(:hour, pho) and
    is_valid_elem?(:day, pday) and
    is_valid_elem?(:weekday, pdow) and
    is_valid_elem?(:month, pmo)
  end

  defp is_valid_elem?(part, elem) when is_list(elem) do
    :lists.all(fn(val) -> is_valid_value?(part, val) end, elem)
  end
  defp is_valid_elem?(part, elem), do: is_valid_value?(part, elem)

  defp is_valid_value?(_, :any),    do: true
  defp is_valid_value?(:minute, V), do: V >= 0   and V <= 59
  defp is_valid_value?(:hour, V),   do: V >= 0   and V <= 23
  defp is_valid_value?(:day, V),    do: V >= -31 and V <= 31 and V !== 0
  defp is_valid_value?(:weekday, V),do: V >= -7  and V <= 7  and V !== 0
  defp is_valid_value?(:month, V),  do: V >= 1   and V <= 12
end
