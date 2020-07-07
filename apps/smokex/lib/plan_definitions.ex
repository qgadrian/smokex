defmodule Smokex.PlanDefinitions do
  @moduledoc """
  Context module to handle plan executions.
  """

  alias Smokex.PlanDefinition

  @doc """
  Creates a new plan definition
  """
  @spec create(map) :: {:ok, PlanDefinition.t()} | {:error, term}
  def create(attrs) do
    %PlanDefinition{}
    |> PlanDefinition.changeset(attrs)
    |> Smokex.Repo.insert()
  end

  @doc """
  Returns all plan definitions
  """
  @spec all() :: list(PlanExecution.t())
  def all() do
    Smokex.Repo.all(PlanDefinition)
  end

  @doc """
  Returns the plan definition with the given id. If no plan is found, returns
  `nil`.
  """
  @spec get(integer) :: PlanDefinition.t() | nil
  def get(id) do
    Smokex.Repo.get(PlanDefinition, id)
  end
end
