defmodule Smokex.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      aliases: aliases(),
      apps_path: "apps",
      build_embedded: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      start_permanent: Mix.env() == :prod,
      version: "0.1.0",
      releases: [
        smokex: [
          include_erts: true,
          include_executables_for: [:unix],
          applications: [
            runtime_tools: :permanent,
            crontab: :permanent,
            sentry: :permanent,
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
      {:crontab, "~> 1.1"},
      {:ex_machina, "~> 2.4"},
      {:sentry, "~> 8.0"}
    ]
  end

  defp aliases do
    [
      setup: ["cmd mix setup"]
    ]
  end

  defp description do
    "Model and contexts for the Smokex umbrella project"
  end
end
