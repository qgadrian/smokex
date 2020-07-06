defmodule Smokex.PlanExecutions do
  @moduledoc """
  Context module to handle plan executions.
  """

  import Ecto.Query

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
  def update_plan_execution(%PlanExecution{} = plan_execution, attrs) when is_map(attrs) do
    plan_execution
    |> PlanExecution.update_changeset(attrs)
    |> Smokex.Repo.update()
  end

  @doc """
  Returns all the executions of a plan definition id.
  """
  @spec list_by_plan_definition(integer) :: list(PlanExecution.t())
  def list_by_plan_definition(plan_definition_id) do
    query =
      from(plan_execution in PlanExecution,
        where: plan_execution.plan_definition_id == ^plan_definition_id,
        select: plan_execution
      )

    Smokex.Repo.all(query)
  end
end
