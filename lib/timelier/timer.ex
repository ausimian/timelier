defmodule Timelier.Timer do
  use GenServer
  @moduledoc false

  @name __MODULE__

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  def init([]) do
    {:ok, tref} = :timer.apply_interval(60_000, Timelier, :check, [])
    {:ok, tref, 0}
  end

  def handle_info(:timeout, state) do
    Timelier.check()
    {:noreply, state}
  end

end
