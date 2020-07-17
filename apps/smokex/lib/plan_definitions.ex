defmodule Smokex.PlanDefinitions do
  @moduledoc """
  Context module to handle plan executions.
  """

  alias Smokex.PlanDefinition
  alias Smokex.PlanExecution

  import Ecto.Query

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
  Preloads the `executions` field with the last updated execution.
  """
  @spec preload_last_execution(PlanDefinition.t()) :: list(PlanDefinition.t())
  def preload_last_execution(%PlanDefinition{} = plan_definition) do
    Smokex.Repo.preload(
      plan_definition,
      executions:
        from(plan_execution in PlanExecution,
          distinct: plan_execution.plan_definition_id,
          order_by: [desc: :updated_at],
          limit: 1
        )
    )
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
  Returns the plan definition with the given id. If no plan is found, raises an
  error.
  """
  @spec get!(integer) :: PlanDefinition.t() | nil
  def get!(id) do
    Smokex.Repo.get!(PlanDefinition, id)
  end

  @doc """
  Updates a plan definition.

  ## Examples
      iex> update(plan_definition, %{name: "test"})
      {:ok, %PlanDefinition{}}
      iex> update(plan_definition, %{name: nil})
      {:error, %Ecto.Changeset{}}
  """
  def update(%PlanDefinition{} = plan_definition, attrs) do
    plan_definition
    |> PlanDefinition.changeset(attrs)
    |> Smokex.Repo.update()

    # TODO notify about the update
    # |> notify_subscribers([:plan_definition, :updated])
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
