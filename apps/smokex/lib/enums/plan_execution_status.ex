defmodule Smokex.Enums.PlanExecutionStatus do
  @moduledoc """
  This module represents a state of a [plan execution](`t:#{PlanExecution}/0`).

  See `t:Smokex.PlanExecution.status/0` for more info.
  """

  use EctoEnum,
    type: :plan_execution_status,
    enums: [:created, :running, :halted, :finished]
end
