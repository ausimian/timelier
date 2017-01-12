defmodule Timelier.Task.Supervisor do
  use Supervisor
  @moduledoc """
  The supervisor for the tasks launched during crontab evaluation.

  All tasks are started as temporary processes under a `simple_one_for_one`
  strategy. Therefore, they will not be restarted.
  """
  @name Timelier.Task.Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  def start_task(mfa) do
    Supervisor.start_child(@name, [mfa])
  end

  def init([]) do
    children = [
      worker(Timelier.Task.Runner, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
