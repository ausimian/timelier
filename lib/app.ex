defmodule Timelier.App do
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
end
