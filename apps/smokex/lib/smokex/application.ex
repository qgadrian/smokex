defmodule Smokex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @oban_config Application.compile_env!(:smokex, Oban)

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Smokex.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Smokex.PubSub},
      # Cache module to store limited features
      %{id: :daily_executions, start: {Cachex, :start_link, [:daily_executions, []]}},
      {Oban, @oban_config},
      Smokex.PlanDefinitions.Scheduler
      # Start a worker by calling: Smokex.Worker.start_link(arg)
      # {Smokex.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Smokex.Supervisor)
  end
end
