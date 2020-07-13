defmodule SmokexWeb.PlanDefinitions.ListView do
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

  def next_execution_started(%PlanDefinition{}) do
    ""
  end
end
