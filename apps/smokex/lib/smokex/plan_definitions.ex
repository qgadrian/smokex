defmodule Smokex.PlanDefinitions do
  @moduledoc """
  Context module to handle plan executions.
  """

  alias Smokex.Users.User
  alias Smokex.Organizations.Organization
  alias Smokex.PlanDefinition
  alias Smokex.PlanExecution
  alias Smokex.PlanDefinitions.Scheduler, as: PlanDefinitionScheduler
  alias SmokexWeb.Telemetry.Reporter, as: TelemetryReporter

  import Ecto.Query

  @doc """
  Creates a new plan definition
  """
  @spec create(User.t(), map) :: {:ok, PlanDefinition.t()} | {:error, term}
  def create(%User{} = user, attrs) do
    %User{organizations: [%Organization{} = organization]} =
      Smokex.Repo.preload(user, :organizations)

    attrs =
      attrs
      |> Map.put("author", user)
      |> Map.put("organization", organization)

    %PlanDefinition{}
    |> PlanDefinition.create_changeset(attrs)
    |> Smokex.Repo.insert()
    |> ensure_job_is_scheduled()
    |> send_event(:create)
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
    |> PlanDefinition.update_changeset(attrs)
    |> Smokex.Repo.update()
    |> ensure_job_is_scheduled()
    |> send_event(:update)

    # TODO notify about the update
    # |> notify_subscribers([:plan_definition, :updated])
  end

  @doc """
  Returns all plan definitions

  TODO remove `all/1` with `User` and only use plans at organization level
  """
  @spec all(nil | User.t() | Organization.t()) :: list(PlanExecution.t())
  def all(nil), do: []

  def all(%User{id: user_id}) do
    query =
      from(plan_definition in PlanDefinition,
        order_by: [desc: :updated_at],
        join: organizations_users in "organizations_users",
        on:
          organizations_users.user_id == ^user_id and
            organizations_users.organization_id == plan_definition.organization_id,
        select: plan_definition
      )

    Smokex.Repo.all(query)
  end

  def all(%Organization{id: organization_id}) do
    query =
      from(plan_definition in PlanDefinition,
        order_by: [desc: :updated_at],
        where: ^organization_id == plan_definition.organization_id,
        select: plan_definition
      )

    Smokex.Repo.all(query)
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
  @spec get(User.t(), integer) :: PlanDefinition.t() | nil
  def get(%User{id: user_id}, id) do
    query =
      from(plan_definition in PlanDefinition,
        join: organizations_users in "organizations_users",
        on:
          organizations_users.user_id == ^user_id and
            organizations_users.organization_id == plan_definition.organization_id,
        where: plan_definition.id == ^id,
        select: plan_definition
      )

    Smokex.Repo.one(query)
  end

  @doc """
  Returns the plan definition with the given id. If no plan is found, raises an
  error.
  """
  @spec get!(User.t(), integer) :: PlanDefinition.t() | nil
  def get!(%User{id: user_id}, id) do
    query =
      from(plan_definition in PlanDefinition,
        join: organizations_users in "organizations_users",
        on:
          organizations_users.user_id == ^user_id and
            organizations_users.organization_id == plan_definition.organization_id,
        where: plan_definition.id == ^id,
        select: plan_definition
      )

    Smokex.Repo.one!(query)
  end

  @doc """
  Subscribes to the plan definition.
  """
  @spec subscribe(PlanDefinition.t() | String.t() | number) :: :ok | {:error, term}
  def subscribe(plan_definition_id) when is_binary(plan_definition_id) do
    Phoenix.PubSub.subscribe(Smokex.PubSub, plan_definition_id, link: true)
  end

  def subscribe(plan_definition_id) when is_number(plan_definition_id) do
    Phoenix.PubSub.subscribe(Smokex.PubSub, "#{plan_definition_id}", link: true)
  end

  def subscribe(%PlanDefinition{} = plan_definition) do
    Phoenix.PubSub.subscribe(Smokex.PubSub, "#{plan_definition.id}", link: true)
  end

  #
  # Private functions
  #

  @spec ensure_job_is_scheduled({:ok, PlanDefinition.t()} | {:error, term}) ::
          {:ok, PlanDefinition.t()} | {:error, term}
  defp ensure_job_is_scheduled(result) do
    with {:ok, %PlanDefinition{} = plan_definition} <- result do
      PlanDefinitionScheduler.update_scheduled_job(plan_definition)
      result
    else
      error -> error
    end
  end

  defp send_event({:ok, %PlanDefinition{id: id}} = result, event) do
    measurement = Map.new([{:action, event}])
    metadata = %{id: id, result: :ok, action: event}

    TelemetryReporter.execute([:plan_definition], measurement, metadata)

    result
  end

  defp send_event({:error, _changeset} = result, event) do
    measurement = Map.new([{:action, event}])
    metadata = %{result: :error, action: event}

    TelemetryReporter.execute([:plan_definition], measurement, metadata)

    result
  end
end
