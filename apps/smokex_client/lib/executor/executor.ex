defmodule SmokexClient.Executor do
  @moduledoc """
  This module starts a plan execution.

  The execution will generate results associated to the execution.

  After and before the execution, the [plan execution](`t:#{PlanExecution}`) is
  updated with the proper status.
  """

  require Logger

  alias SmokexClient.ExecutionState
  alias SmokexClient.Worker
  alias SmokexClient.Parsers.Yaml.Parser, as: YamlParser

  alias Smokex.PlanExecutions
  alias Smokex.PlanDefinition
  alias Smokex.PlanExecution

  @spec execute(PlanExecution.t()) :: {:ok, term} | {:error, term}
  def execute(
        %PlanExecution{
          id: id,
          status: :created,
          plan_definition: %PlanDefinition{content: content}
        } = plan_execution
      ) do
    # TODO stop using a process to handle the state here
    ExecutionState.start_link()

    # TODO this code is currently expecting a YAML file, but the parser could
    # be different depending on the type of content
    content
    |> YamlParser.parse()
    |> case do
      {:ok, list_of_requests} ->
        try do
          PlanExecutions.start(plan_execution)

          Enum.each(list_of_requests, &Worker.execute(&1, plan_execution))

          PlanExecutions.finish(plan_execution)
        catch
          {:error, reason} ->
            Logger.error("Execution #{id} error: #{inspect(reason)}")
            PlanExecutions.halt(plan_execution)
        end

      {:error, reason} ->
        Logger.error("Execution #{id} error: #{inspect(reason)}")
        PlanExecutions.halt(plan_execution)
    end
  end

  @spec execute(PlanDefinition.t()) :: {:ok, term} | {:error, term}
  def execute(%PlanDefinition{content: content} = plan_definition) do
    # TODO stop using a process to handle the state here
    ExecutionState.start_link()

    {:ok, plan_execution} = PlanExecutions.create_plan_execution(plan_definition)

    # TODO this code is currently expecting a YAML file, but the parser could
    # be different depending on the type of content
    content
    |> YamlParser.parse()
    |> case do
      {:ok, list_of_requests} ->
        try do
          PlanExecutions.start(plan_execution)

          Enum.each(list_of_requests, &Worker.execute(&1, plan_execution))

          PlanExecutions.finish(plan_execution)
        catch
          {:error, reason} ->
            Logger.error("Execution #{plan_execution.id} error: #{inspect(reason)}")
            PlanExecutions.halt(plan_execution)
        end

      {:error, reason} ->
        Logger.error("Execution #{plan_execution.id} error: #{inspect(reason)}")
        PlanExecutions.halt(plan_execution)
    end
  end
end
