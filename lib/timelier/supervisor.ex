defmodule Timelier.Supervisor do
  use Supervisor
  @moduledoc false

  @name Timelier.Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  def init([]) do
    children = [
      supervisor(Timelier.Task.Supervisor, []),
      worker(Timelier.Server, []),
      worker(Timelier.Timer, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
