defmodule Smokex.PlanExecutions.Status do
  @moduledoc """
  Context module to handle plan executions.
  """

  alias Smokex.PlanExecutions.Subscriber

  alias Smokex.Limits
  alias Smokex.Organizations
  alias Smokex.PlanDefinition
  alias Smokex.PlanExecution
  alias Smokex.PlanExecutions
  alias Smokex.Notifications
  alias SmokexWeb.Telemetry.Reporter, as: TelemetryReporter

  @type ecto_plan_execution_result :: {:ok, PlanExecution.t()} | {:error, Ecto.Changeset.t()}

  @typedoc """
  The optional parameters to filter plan executions.
  """
  @type filter_opts :: [
          per_page: integer,
          plan_definition_id: integer,
          status: PlanExecution.status()
        ]

  @type last_execution_opts :: [
          plan_definition_id: integer,
          limit: integer
        ]

  @doc """
  Updates a plan execution as started.

  TODO trigger the job start
  """
  @spec start(PlanExecution.t(), integer) :: {:ok, PlanExecution.t()} | {:error, term}
  def start(%PlanExecution{} = plan_execution, total_executions \\ nil) do
    %PlanExecution{plan_definition: %PlanDefinition{organization: organization}} =
      plan_execution = Smokex.Repo.preload(plan_execution, plan_definition: :organization)

    unless Organizations.subscribed?(organization) do
      Limits.increase_daily_executions(organization)
    end

    plan_execution
    |> PlanExecutions.update(%{
      status: :running,
      total_executions: total_executions,
      started_at: NaiveDateTime.utc_now()
    })
    |> Subscriber.notify_change(:started)
    |> Notifications.maybe_notify_change()
  end

  @doc """
  Finishes a plan execution and sets it as `halted`.
  """
  @spec halt(PlanExecution.t()) :: {:ok, PlanExecution.t()} | {:error, term}
  def halt(%PlanExecution{} = plan_execution) do
    plan_execution
    |> PlanExecutions.update(%{status: :halted, finished_at: NaiveDateTime.utc_now()})
    |> Subscriber.notify_change(:halted)
    |> Notifications.maybe_notify_change()
  end

  @doc """
  Updates a plan execution as finished.
  """
  @spec finish(PlanExecution.t()) :: {:ok, PlanExecution.t()} | {:error, term}
  def finish(%PlanExecution{} = plan_execution) do
    plan_execution
    |> PlanExecutions.update(%{
      status: :finished,
      finished_at: NaiveDateTime.utc_now()
    })
    |> report_execution_time()
    |> Subscriber.notify_change(:finished)
    |> Notifications.maybe_notify_change()
  end

  #
  # Private functions
  #

  @spec report_execution_time(ecto_plan_execution_result) :: ecto_plan_execution_result
  defp report_execution_time(
         {:ok, %PlanExecution{id: id, status: status} = plan_execution} = result
       ) do
    execution_time = PlanExecutions.execution_time(plan_execution)

    measurement = %{execution_time: execution_time}
    metadata = %{id: id, status: status}

    TelemetryReporter.execute([:plan_execution], measurement, metadata)

    result
  end

  defp report_execution_time(error), do: error
end
