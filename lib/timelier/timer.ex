defmodule Timelier.Timer do
  use GenServer
  @moduledoc """
  Responsible for the timer that checks the crontab every minute.
  """
  @name __MODULE__

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  def init([]) do
    {:ok, [], 0}
  end

  def handle_info(:timeout, state) do
    Timelier.check()
    {:noreply, state, 60_000}
  end
end
