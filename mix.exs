defmodule Timelier.Mixfile do
  use Mix.Project

  def project do
    [app: :timelier,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.html": :test],
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
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:earmark, "~> 1.0.3", only: :dev},
      {:ex_doc, "~> 0.12", only: :dev},
      {:excoveralls, "~> 0.6", only: :test},
      {:quixir, "~> 0.9", only: :test}
    ]
  end

  defp default_provider do
    {Application, :get_env, [:timelier, :crontab, []]}
  end
end
