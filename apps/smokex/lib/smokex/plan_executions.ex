defmodule Smokex.PlanExecutions do
  @moduledoc """
  Context module to handle plan executions.
  """

  import Ecto.Query

  alias Smokex.Users.User
  alias Smokex.PlanExecution
  alias Smokex.PlanDefinition
  alias SmokexWeb.Telemetry.Reporter, as: TelemetryReporter

  @typedoc """
  The optional parameters to filter plan executions.
  """
  @type filter_opts :: [
          per_page: integer,
          plan_definition_id: integer,
          status: PlanExecution.status()
        ]

  @type last_execution_opts :: [
          plan_definition_id: integer,
          limit: integer
        ]

  @doc """
  Creates a new plan execution.

  The user can be the user that triggered a manual execution, or `nil` if the
  execution was scheduled.
  """
  @spec create_plan_execution(User.t() | nil, PlanDefinition.t()) ::
          {:ok, PlanExecution.t()} | {:error, term}
  def create_plan_execution(user_or_nil, %PlanDefinition{} = plan_definition) do
    result =
      %PlanExecution{}
      |> PlanExecution.create_changeset(%{
        plan_definition: plan_definition,
        trigger_user: user_or_nil
      })
      |> Smokex.Repo.insert()
      |> send_event(:create)

    with {:ok, plan_execution} <- result do
      Smokex.PlanExecutions.Subscriber.notify_created(plan_definition, plan_execution)
    end

    result
  end

  @doc """
  Updates a plan execution
  """
  @spec update(PlanExecution.t(), map) :: {:ok, PlanExecution.t()} | {:error, term}
  def update(%PlanExecution{} = plan_execution, attrs) when is_map(attrs) do
    plan_execution
    |> PlanExecution.update_changeset(attrs)
    |> Smokex.Repo.update()
    |> send_event(:update)
  end

  @doc """
  Returns the plan execution with the given id.

  If no execution is found, raises an exception.
  """
  @spec get(id :: integer) :: PlanExecution.t() | no_return
  def get(id) do
    query =
      from(plan_execution in PlanExecution,
        join: plan_definition in PlanDefinition,
        on: plan_execution.plan_definition_id == plan_definition.id,
        where: plan_execution.id == ^id,
        select: plan_execution
      )

    Smokex.Repo.one(query)
  end

  @doc """
  Returns the plan execution with the given id.

  If no execution is found, raises an exception.
  """
  @spec get!(User.t(), id :: integer) :: PlanExecution.t() | no_return
  def get!(%User{} = user, id) do
    user
    |> list_executions_query()
    |> where(id: ^id)
    |> Smokex.Repo.one!()
  end

  @doc """
  Returns all plans definitions by the given params.

  TODO remove the nil asserting once the persisted session storage works fine.
  But keep in mind possible unauthenticated error as well once the session
  expires.
  """
  @spec all(User.t(), integer, filter_opts()) :: list(PlanExecution.t())
  def all(user_or_nil, current_page, opts \\ [])

  def all(nil, _current_page, _opts), do: []

  def all(%User{} = user, current_page, opts) do
    # TODO make this configurable
    per_page = Keyword.get(opts, :per_page, 20)

    user
    |> list_executions_query(opts)
    |> offset((^current_page - 1) * ^per_page)
    |> limit(^per_page)
    |> order_by(desc: :updated_at)
    |> Smokex.Repo.all()
  end

  @doc """
  Returns the *limit* number of executions.

  See `t:last_execution_opts/0` to check the available filter.
  """
  # TODO get the plan definition in opts and create a maybe function
  @spec last_executions(User.t(), last_execution_opts) :: list(PlanExecution.t())
  # TODO add a config to limit
  def last_executions(%User{} = user, opts) do
    # TODO make the limit configurable
    limit = Keyword.get(opts, :limit, 10)

    user
    |> list_executions_query(opts)
    |> limit(^limit)
    |> Smokex.Repo.all()
  end

  @doc """
  Returns the summary of the executions.
  """
  @spec executions_summary(User.t()) :: list(PlanExecution.t())
  def executions_summary(%User{id: user_id}) do
    query =
      from(plan_execution in PlanExecution,
        join: plan_definition in PlanDefinition,
        on: plan_execution.plan_definition_id == plan_definition.id,
        join: organizations_users in "organizations_users",
        on:
          organizations_users.user_id == ^user_id and
            organizations_users.organization_id == plan_definition.organization_id,
        group_by: plan_execution.status,
        select: {plan_execution.status, count(plan_execution.status)}
      )

    Smokex.Repo.all(query)
  end

  @doc """
  Returns the total number of executions for the given criteria.
  """
  @spec count_total(User.t(), filter_opts()) :: list(PlanExecution.t())
  def count_total(user_or_nil, opts \\ [])

  def count_total(nil, _opts), do: 0

  def count_total(%User{} = user, opts) do
    user
    |> list_executions_query(opts)
    |> Smokex.Repo.aggregate(:count)
  end

  @doc """
  Returns the total number of executions.

  TODO delete this function as duplicates `count_total`
  """
  @spec total_executions(User.t()) :: list(PlanExecution.t())
  def total_executions(%User{} = user), do: count_total(user, [])

  @doc """
  Returns all the executions of a plan definition id that are in the given
  status, filtered by status.
  """
  @typep filter_status :: String.t() | PlanExecution.status() | :all
  @spec filtered_executions(integer, filter_status) :: list(PlanExecution.t())
  def filtered_executions(plan_definition_id, :all) do
    query =
      from(plan_execution in PlanExecution,
        where: plan_execution.plan_definition_id == ^plan_definition_id,
        order_by: [desc: :updated_at],
        select: plan_execution
      )

    Smokex.Repo.all(query)
  end

  def filtered_executions(plan_definition_id, status) do
    query =
      from(plan_execution in PlanExecution,
        where: plan_execution.plan_definition_id == ^plan_definition_id,
        where: plan_execution.status == ^status,
        order_by: [desc: :updated_at],
        select: plan_execution
      )

    Smokex.Repo.all(query)
  end

  @doc """
  Returns the execution time, in seconds.

  In order to process the exeuction time the plan execution needs to have a
  start and finish date, and a **finished state**. If the execution has no
  finished state, returns `nil`.
  """
  @spec execution_time(PlanExecution.t()) :: integer | nil
  def execution_time(%PlanExecution{
        started_at: started_at,
        finished_at: finished_at,
        status: status
      })
      when status in [:finished, :halted] do
    NaiveDateTime.diff(finished_at, started_at, :second)
  end

  def execution_time(_plan_execution), do: nil

  defdelegate subscribe(plan_execution), to: Smokex.PlanExecutions.Subscriber

  #
  # Private functions
  #

  @spec list_executions_query(User.t(), keyword) :: Ecto.Query.t()
  defp list_executions_query(%User{id: user_id}, opts \\ []) do
    plan_definition_id = Keyword.get(opts, :plan_definition_id)
    status = Keyword.get(opts, :status, :all)

    from(plan_execution in PlanExecution,
      join: plan_definition in PlanDefinition,
      on: plan_execution.plan_definition_id == plan_definition.id,
      join: organizations_users in "organizations_users",
      on:
        organizations_users.user_id == ^user_id and
          organizations_users.organization_id == plan_definition.organization_id,
      select: plan_execution
    )
    |> maybe_query_by_status(status)
    |> maybe_query_by_plan_definition(plan_definition_id)
  end

  @spec maybe_query_by_plan_definition(Ecto.Query.t(), String.t()) :: Ecto.Query.t()
  defp maybe_query_by_plan_definition(query, ""), do: query

  defp maybe_query_by_plan_definition(query, plan_definition_id)
       when is_binary(plan_definition_id) do
    where(query, plan_definition_id: ^plan_definition_id)
  end

  defp maybe_query_by_plan_definition(query, _), do: query

  @spec maybe_query_by_status(Ecto.Query.t(), String.t()) :: Ecto.Query.t()
  defp maybe_query_by_status(query, :all), do: query

  defp maybe_query_by_status(query, status) do
    where(query, status: ^status)
  end

  defp send_event({:ok, %PlanExecution{id: id, status: status} = plan_execution} = result, event) do
    plan_execution = Smokex.Repo.preload(plan_execution, :plan_definition)

    measurement = Map.new([{:action, event}])

    metadata = %{
      id: id,
      result: :ok,
      action: event,
      status: status,
      plan_definition_id: plan_execution.plan_definition.id
    }

    TelemetryReporter.execute([:plan_execution], measurement, metadata)

    result
  end

  defp send_event({:error, _changeset} = result, event) do
    measurement = Map.new([{:action, event}])
    metadata = %{result: :error, action: event}

    TelemetryReporter.execute([:plan_execution], measurement, metadata)

    result
  end
end
