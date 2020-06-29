defmodule SmokexClient.Mixfile do
  use Mix.Project

  @version "0.3.0"

  def project do
    [
      app: :smokex_client,
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
      {:smokex, in_umbrella: true},
      # Main deps
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.2"},
      {:yaml_elixir, "~> 2.4.0"},
      {:kitchen_sink, "~> 1.3"},

      # Test, docs and QA deps
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:sobelow, "~> 0.10.3"},
      {:httparrot, "~> 1.2", only: :test, git: "https://github.com/qgadrian/httparrot.git"},
      {:ex_doc, "~> 0.22.1"}
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
end
