defmodule SmokexWeb.PlanDefinitions.ListView do
  import Crontab.CronExpression

  require Logger

  alias Smokex.PlanDefinition
  alias SmokexWeb.PlanExecutions.Components.StatusBadge

  def last_execution_started(%PlanDefinition{executions: []}) do
    ""
  end

  def last_execution_started(%PlanDefinition{executions: [plan_execution]}) do
    plan_execution.started_at
  end

  def last_execution_status(%PlanDefinition{executions: []}) do
    ""
  end

  def last_execution_status(%PlanDefinition{executions: [plan_execution]}) do
    StatusBadge.new(plan_execution)
  end

  def next_execution_started(%PlanDefinition{cron_sentence: cron_sentence}) do
    with {:ok, cron_expression} <- Crontab.CronExpression.Parser.parse(cron_sentence),
         {:ok, date} <- Crontab.Scheduler.get_next_run_date(cron_expression) do
      date
    else
      _ ->
        Logger.error("Error parsing cron sentence: #{cron_sentence}")
        ""
    end
  end
end
