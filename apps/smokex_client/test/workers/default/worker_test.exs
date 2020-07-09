defmodule SmokexClient.Test.Workers.Default do
  use ExUnit.Case

  import Smokex.TestSupport.Factories

  alias SmokexClient.Executor
  alias Smokex.PlanExecution

  setup do
    plan_definition = insert(:plan_definition, content: "- get: \n an: error")
    plan_execution = insert(:plan_execution, plan_definition: plan_definition)

    [
      plan_execution: plan_execution
    ]
  end

  test "Given a yaml steps when launch worker then each valid step is processed", %{
    plan_execution: plan_execution
  } do
    assert {:ok, %PlanExecution{status: :halted}} = Executor.execute(plan_execution)
  end
end
