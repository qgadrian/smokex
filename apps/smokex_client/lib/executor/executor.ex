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

  alias Smokex.Limits
  alias Smokex.PlanExecutions.Status, as: PlanExecutionStatus
  alias Smokex.PlanExecution

  @doc """
  Starts an execution of a plan execution.

  Keep in mind this can be a long living executing and the calling process
  will be potentially blocked for a long time.

  In order to let this function execute the `#{PlanExecution}` the status must
  have the `created` state. If it does not, it means the execution is in a
  *corrupted state* and it will halted by the worker.
  """
  @spec execute(PlanExecution.t(), keyword) :: {:ok, term} | {:error, term}
  def execute(_plan_execution, opts \\ [halt: true])

  def execute(
        %PlanExecution{
          id: id,
          status: :created
        } = plan_execution,
        opts
      ) do
    Logger.info("Start execution #{id}")

    if Limits.can_start_execution?(plan_execution) do
      do_execute(plan_execution, opts)
    else
      PlanExecutionStatus.halt(plan_execution)

      {:ok, _result} =
        Smokex.Results.create(%{
          plan_execution: plan_execution,
          failed_assertions: [%{error: "Free limit reached"}],
          result: :error
        })

      {:error, :reached_free_limit}
    end
  end

  def execute(%PlanExecution{id: id, status: status} = plan_execution, _opts) do
    Logger.info(
      "Execution #{id} cannot run, it will halted instead because has invalid status: #{status}"
    )

    PlanExecutionStatus.halt(plan_execution)

    {:ok, plan_execution}
  end

  #
  # Private functions
  #

  @spec do_execute(PlanExecution.t(), keyword) :: {:ok, term} | {:error, term}
  defp do_execute(%PlanExecution{id: id} = plan_execution, opts) do
    content =
      plan_execution
      |> Smokex.Repo.preload(:plan_definition)
      |> Map.get(:plan_definition)
      |> Map.get(:content)

    # TODO this code is currently expecting a YAML file, but the parser could
    # be different depending on the type of content
    content
    |> YamlParser.parse()
    |> case do
      {:ok, list_of_requests} ->
        {:ok, plan_execution} =
          PlanExecutionStatus.start(plan_execution, length(list_of_requests))

        try do
          Enum.reduce(list_of_requests, nil, fn
            request, nil ->
              execution_context = ExecutionContext.new(plan_execution, opts)

              Worker.execute(request, plan_execution, execution_context)

            request, execution_context ->
              Worker.execute(request, plan_execution, execution_context)
          end)

          PlanExecutionStatus.finish(plan_execution)
        catch
          {:error, reason} ->
            Logger.error("Execution #{id} error: #{inspect(reason)}")
            PlanExecutionStatus.halt(plan_execution)
        end

        {:ok, plan_execution}

      {:error, reason} ->
        Logger.error("Execution #{id} error: #{inspect(reason)}")
        PlanExecutionStatus.halt(plan_execution)
    end
  end
end
