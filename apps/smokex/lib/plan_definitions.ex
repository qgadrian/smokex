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

  @doc """
  Subscribes to the plan definition.
  """
  @spec subscribe(PlanDefinition.t() | String.t()) :: :ok | {:error, term}
  def subscribe(plan_definition_id) when is_binary(plan_definition_id) do
    Phoenix.PubSub.subscribe(Smokex.PubSub, plan_definition_id, link: true)
  end

  def subscribe(%PlanDefinition{} = plan_definition) do
    Phoenix.PubSub.subscribe(Smokex.PubSub, "#{plan_definition.id}", link: true)
  end
end
