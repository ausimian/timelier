defmodule Timelier.Task.Runner do
  use GenServer
  @moduledoc false

  def start_link(mfa) do
    GenServer.start_link(__MODULE__, mfa)
  end

  def init(mfa) do
    GenServer.cast(self(), {:run, mfa})
    {:ok, []}
  end

  def handle_cast({:run, {mod, func, args}}, state) do
    apply(mod, func, args)
    {:stop, :normal, state}
  end
end
