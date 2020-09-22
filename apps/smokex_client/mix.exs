defmodule SmokexClient.Mixfile do
  use Mix.Project

  @version "0.3.0"

  def project do
    [
      app: :smokex_client,
      description: description(),
      version: @version,
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: extra_applications(Mix.env())
    ]
  end

  def extra_applications(:test), do: [:httparrot]
  def extra_applications(_), do: []

  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.22.1"},
      {:exjsonpath, "~> 0.1"},
      {:httparrot, "~> 1.3", only: :test},
      {:httpoison, "~> 1.6"},
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.2"},
      {:slack, "~> 0.23.5"},
      {:smokex, in_umbrella: true},
      {:sobelow, "~> 0.10.3"},
      {:yaml_elixir, "~> 2.4.0"}
    ]
  end

  defp aliases do
    [
      compile: ["compile --warnings-as-errors"],
      build: ["compile", "escript.build"],
      coveralls: ["coveralls.html"],
      "coveralls.html": ["coveralls.html"]
    ]
  end

  defp description do
    "Business logic for the Smokex umbrella project"
  end
end
