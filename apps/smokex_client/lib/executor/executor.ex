defmodule SmokexClient.Executor do
  @moduledoc """
  This module starts a plan execution.

  The execution will generate results associated to the execution.

  After and before the execution, the [plan execution](`t:#{PlanExecution}`) is
  updated with the proper status.
  """

  require Logger

  alias SmokexClient.Worker
  alias SmokexClient.ExecutionContext
  alias SmokexClient.Parsers.Yaml.Parser, as: YamlParser

  alias Smokex.PlanExecutions.Executor
  alias Smokex.PlanDefinition
  alias Smokex.PlanExecution

  # TODO provide a `halt` option feature
  @spec execute(PlanExecution.t()) :: {:ok, term} | {:error, term}
  def execute(
        %PlanExecution{
          id: id,
          status: :created,
          plan_definition: %PlanDefinition{content: content}
        } = plan_execution,
        opts \\ [halt: true]
      ) do
    # TODO this code is currently expecting a YAML file, but the parser could
    # be different depending on the type of content
    content
    |> YamlParser.parse()
    |> case do
      {:ok, list_of_requests} ->
        {:ok, plan_execution} = Executor.start(plan_execution, length(list_of_requests))

        #  TODO do not just spawn a process
        spawn(fn ->
          try do
            Enum.reduce(list_of_requests, nil, fn
              request, nil ->
                execution_context = %ExecutionContext{
                  halt_on_error: Keyword.get(opts, :halt)
                }

                Worker.execute(request, plan_execution, execution_context)

              request, execution_context ->
                Worker.execute(request, plan_execution, execution_context)
            end)

            Executor.finish(plan_execution)
          catch
            {:error, reason} ->
              Logger.error("Execution #{id} error: #{inspect(reason)}")
              Executor.halt(plan_execution)
          end
        end)

        {:ok, plan_execution}

      {:error, reason} ->
        Logger.error("Execution #{id} error: #{inspect(reason)}")
        Executor.halt(plan_execution)
    end
  end
end
