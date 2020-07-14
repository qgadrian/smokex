defmodule Smokex.PlanExecutions do
  @moduledoc """
  Context module to handle plan executions.
  """

  import Ecto.Query

  alias Smokex.PlanExecution
  alias Smokex.PlanDefinition

  @doc """
  Creates a new plan execution
  """
  @spec create_plan_execution(PlanDefinition.t()) :: {:ok, PlanExecution.t()} | {:error, term}
  def create_plan_execution(%PlanDefinition{} = plan_definition) do
    result =
      %PlanExecution{}
      |> PlanExecution.create_changeset(%{plan_definition: plan_definition})
      |> Smokex.Repo.insert()

    with {:ok, plan_execution} <- result do
      Phoenix.PubSub.broadcast(
        Smokex.PubSub,
        "#{plan_definition.id}",
        {:created, plan_execution}
      )
    end

    result
  end

  @doc """
  Returns all plans definitions executions.
  """
  @spec all() :: list(PlanExecution.t())
  def all() do
    query =
      from(plan_execution in PlanExecution,
        order_by: [desc: :updated_at],
        select: plan_execution
      )

    Smokex.Repo.all(query)
  end

  @doc """
  Returns the plan execution with the given id. If no execution is found,
  returns `nil`.
  """
  @spec get(integer) :: PlanExecution.t() | nil
  def get(id) do
    Smokex.Repo.get(PlanExecution, id)
  end

  @doc """
  Returns all plans definitions by the given params.
  """
  @spec by_status(PlanExecution.status() | String.t()) :: list(PlanExecution.t())
  def by_status(status) do
    query =
      from(plan_execution in PlanExecution,
        where: plan_execution.status == ^status,
        order_by: [desc: :updated_at],
        select: plan_execution
      )

    Smokex.Repo.all(query)
  end

  @doc """
  Returns the last *number* of executions of a plan definition.
  """
  @spec last_executions(integer, integer) :: list(PlanExecution.t())
  # TODO add a config to limit
  def last_executions(plan_definition_id, limit \\ 10) when is_number(limit) do
    query =
      from(plan_execution in PlanExecution,
        where: plan_execution.plan_definition_id == ^plan_definition_id,
        limit: ^limit,
        order_by: [desc: :updated_at],
        select: plan_execution
      )

    Smokex.Repo.all(query)
  end

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
  Updates a plan execution as started.
  """
  @spec start(PlanExecution.t()) :: {:ok, PlanExecution.t()} | {:error, term}
  def start(%PlanExecution{} = plan_execution) do
    plan_execution
    |> update_plan_execution(%{
      status: :running,
      started_at: NaiveDateTime.utc_now()
    })
    |> notify_change(:started)
  end

  @doc """
  Finishes a plan execution and sets it as `halted`.
  """
  @spec halt(PlanExecution.t()) :: {:ok, PlanExecution.t()} | {:error, term}
  def halt(%PlanExecution{} = plan_execution) do
    plan_execution
    |> update_plan_execution(%{status: :halted, finished_at: NaiveDateTime.utc_now()})
    |> notify_change(:halted)
  end

  @doc """
  Updates a plan execution as finished.
  """
  @spec finish(PlanExecution.t()) :: {:ok, PlanExecution.t()} | {:error, term}
  def finish(%PlanExecution{} = plan_execution) do
    plan_execution
    |> update_plan_execution(%{
      status: :finished,
      finished_at: NaiveDateTime.utc_now()
    })
    |> notify_change(:finished)
  end

  @doc """
  Updates a plan execution
  """
  @spec update_plan_execution(PlanExecution.t(), map) :: {:ok, PlanExecution.t()} | {:error, term}
  def update_plan_execution(%PlanExecution{} = plan_execution, attrs) when is_map(attrs) do
    plan_execution
    |> PlanExecution.update_changeset(attrs)
    |> Smokex.Repo.update()
  end

  @doc """
  Subscribes to the plan execution.
  """
  @spec subscribe(PlanExecution.t()) :: :ok | {:error, term}
  def subscribe(%PlanExecution{} = plan_execution) do
    Phoenix.PubSub.subscribe(Smokex.PubSub, "#{plan_execution.id}", link: true)
  end

  @spec subscribe(String.t()) :: :ok | {:error, term}
  def subscribe(plan_execution_id) when is_binary(plan_execution_id) do
    Phoenix.PubSub.subscribe(Smokex.PubSub, plan_execution_id, link: true)
  end

  @doc """
  Subscribes to the plan execution.
  """
  @spec subscribe(list(PlanExecution.t())) :: :ok | {:error, term}
  def subscribe([]), do: :ok

  def subscribe([%PlanExecution{} | _] = plan_executions) when is_list(plan_executions) do
    Enum.each(plan_executions, &subscribe/1)
  end

  #
  # Private functions
  #

  @spec notify_change(term, PlanExecution.status()) :: term
  defp notify_change(result, event) do
    with {:ok, plan_execution} <- result do
      Phoenix.PubSub.broadcast(
        Smokex.PubSub,
        "#{plan_execution.id}",
        {event, plan_execution}
      )
    end

    result
  end
end
