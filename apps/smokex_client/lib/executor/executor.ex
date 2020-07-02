defmodule SmokexClient.Executor do
  alias SmokexClient.ExecutionState
  alias SmokexClient.Worker

  alias Smokex.PlanExecutions
  alias Smokex.PlanDefinition

  @spec execute(list(struct)) :: atom
  def execute(steps) do
    ExecutionState.start_link()

    # TODO receive plan definition
    plan_definition = Smokex.Repo.get(PlanDefinition, 1)

    {:ok, plan_execution} = PlanExecutions.create_plan_execution(plan_definition)

    try do
      Enum.each(steps, &Worker.execute(&1))

      PlanExecutions.update_plan_execution(plan_execution, %{status: :finished})
    catch
      {:error, reason} -> {:error, reason}
    end
  end
end
