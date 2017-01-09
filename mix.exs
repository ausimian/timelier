defmodule Timelier.Mixfile do
  use Mix.Project

  def project do
    [app: :timelier,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger],
     mod: {Timelier, []},
     env: [{:provider, default_provider()},
           {:timezone, :local}]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:earmark, "~> 1.0.3", only: :dev},
      {:ex_doc, "~> 0.12", only: :dev}
    ]
  end

  defp default_provider do
    {Application, :get_env, [Timelier, :crontab, []]}
  end
end
