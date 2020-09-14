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
      %{id: :executions_limit_track, start: {Cachex, :start_link, [:executions_limit_track, []]}},
      {Oban, @oban_config},
      Smokex.PlanDefinitions.Scheduler
      # Start a worker by calling: Smokex.Worker.start_link(arg)
      # {Smokex.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Smokex.Supervisor)
  end

  # TODO
  #
  # This is DANGEROUS, it will slow down the application start as long a the
  # plan definitions are created. This should be done asynchronous when the
  # application starts.
  #
  # Read the README about the Quantum job persistence.
  #
  def start_phase(:start_scheduled_jobs, _start_type, _args) do
    require Logger

    Smokex.PlanDefinition
    |> Smokex.Repo.all()
    |> Enum.each(fn plan_definition ->
      Smokex.PlanDefinitions.Scheduler.create_scheduled_job(plan_definition)
      Logger.info("Scheduled plan definition #{plan_definition.id}")
    end)

    :ok
  end
end
