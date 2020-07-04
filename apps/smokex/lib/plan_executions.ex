defmodule Smokex.PlanExecutions do
  @moduledoc """
  Context module to handle plan executions.
  """

  alias Smokex.PlanExecution
  alias Smokex.PlanDefinition

  @doc "Creates a new plan execution"
  @spec create_plan_execution(PlanDefinition.t()) :: {:ok, PlanExecution.t()} | {:error, term}
  def create_plan_execution(%PlanDefinition{} = plan_definition) do
    %PlanExecution{}
    |> PlanExecution.create_changeset(%{plan_definition: plan_definition})
    |> Smokex.Repo.insert()
  end

  @doc "Updates a plan execution"
  @spec update_plan_execution(PlanExecution.t(), map) :: {:ok, PlanExecution.t()} | {:error, term}
  def update_plan_execution(%PlanExecution{} = plan_execution, attrs) do
    plan_execution
    |> PlanExecution.update_changeset(attrs)
    |> Smokex.Repo.update()
  end
end
