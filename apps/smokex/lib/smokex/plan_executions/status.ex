defmodule Smokex.PlanExecutions.Status do
  @moduledoc """
  Context module to handle plan executions.
  """

  alias Smokex.PlanExecutions.Subscriber

  alias Smokex.Limits
  alias Smokex.Users
  alias Smokex.PlanExecution
  alias Smokex.PlanExecutions
  alias Smokex.Notifications

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
    plan_execution = Smokex.Repo.preload(plan_execution, :user)

    unless Users.subscribed?(plan_execution.user) do
      Limits.increase_daily_executions(plan_execution.plan_definition_id)
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
    |> Subscriber.notify_change(:finished)
    |> Notifications.maybe_notify_change()
  end
end
