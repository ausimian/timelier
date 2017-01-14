defmodule Timelier.Mixfile do
  use Mix.Project

  def project do
    [app: :timelier,
     version: "0.9.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.html": :test],
     deps: deps(),

     # Documentation
     name: "Timelier",
     description: "A cron-style scheduler for Elixir.",
     source_url: repo(),

     # Package
     package: package()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [],
     mod: {Timelier, []},
     env: [{:provider, default_provider()},
           {:timezone, :local}]]
  end

  defp package do
    [
      name: :timelier,
      maintainers: ["Nick Gunn"],
      licences: ["MIT"],
      links: %{"GitHub" => repo()}
    ]
  end

  defp deps do
    [
      {:credo,       "~> 0.5",   only: [:dev, :test]},
      {:earmark,     "~> 1.0.3", only: :dev},
      {:ex_doc,      "~> 0.12",  only: :dev},
      {:excoveralls, "~> 0.6",   only: :test},
      {:quixir,      "~> 0.9",   only: :test}
    ]
  end

  defp repo, do: "https://github.com/ausimian/timelier"

  defp default_provider do
    {Timelier, :get_crontab, []}
  end
end
