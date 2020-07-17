defmodule Smokex.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      aliases: aliases(),
      apps_path: "apps",
      deps: deps(),
      start_permanent: Mix.env() == :prod,
      version: "0.1.0",
      releases: [
        smokex: [
          applications: [
            runtime_tools: :permanent,
            crontab: :permanent,
            smokex: :permanent,
            smokex_web: :permanent,
            smokex_client: :permanent
          ]
        ]
      ]
    ]
  end

  defp deps do
    [
      {:ex_machina, "~> 2.4"},
      {:crontab, "~> 1.1"}
    ]
  end

  defp aliases do
    [
      setup: ["cmd mix setup"]
    ]
  end
end
