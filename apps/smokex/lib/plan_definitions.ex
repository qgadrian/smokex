defmodule Smokex.PlanDefinitions do
  @moduledoc """
  Context module to handle plan executions.
  """

  alias Smokex.PlanDefinition

  @doc "Creates a new plan definition"
  @spec create(map) :: {:ok, PlanDefinition.t()} | {:error, term}
  def create(attrs) do
    %PlanDefinition{}
    |> PlanDefinition.changeset(attrs)
    |> Smokex.Repo.insert()
  end

  @doc "Returns all plan definitions"
  @spec all() :: list(PlanExecution.t())
  def all() do
    Smokex.Repo.all(PlanDefinition)
  end
end
