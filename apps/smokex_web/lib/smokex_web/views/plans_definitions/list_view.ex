defmodule SmokexWeb.PlanDefinitions.ListView do
  require Logger

  alias Smokex.PlanDefinition
  alias SmokexWeb.PlanExecutions.Components.StatusBadge

  @spec last_execution_started(PlanDefinition.t()) :: String.t() | DateTime.t()
  def last_execution_started(%PlanDefinition{executions: []}) do
    ""
  end

  def last_execution_started(%PlanDefinition{executions: [plan_execution]}) do
    plan_execution.started_at
  end

  @spec last_execution_status(PlanDefinition.t()) :: term
  def last_execution_status(%PlanDefinition{executions: []}) do
    ""
  end

  def last_execution_status(%PlanDefinition{executions: [plan_execution]}) do
    StatusBadge.new(plan_execution)
  end

  @spec next_execution_started(PlanDefinition.t()) :: String.t() | DateTime.t()
  def next_execution_started(%PlanDefinition{cron_sentence: cron_sentence}) do
    with {:ok, cron_expression} <- Crontab.CronExpression.Parser.parse(cron_sentence),
         {:ok, date} <- Crontab.Scheduler.get_next_run_date(cron_expression) do
      date
    else
      _ ->
        Logger.error("Error parsing cron expression: #{cron_sentence}")
        ""
    end
  end
end
