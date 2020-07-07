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
    %PlanExecution{}
    |> PlanExecution.create_changeset(%{plan_definition: plan_definition})
    |> Smokex.Repo.insert()
  end

  @doc """
  Returns all plans definitions executions.
  """
  @spec all() :: list(PlanExecution.t())
  def all() do
    Smokex.Repo.all(PlanExecution)
  end

  @doc """
  Returns all plans definitions by the given params.
  """
  @spec by_status(PlanExecution.status() | String.t()) :: list(PlanExecution.t())
  def by_status(status) do
    query =
      from(plan_execution in PlanExecution,
        where: plan_execution.status == ^status,
        select: plan_execution
      )

    Smokex.Repo.all(query)
  end

  @doc """
  Returns all the executions of a plan definition id.
  """
  @spec get_by_plan_definition(integer, integer) :: list(PlanExecution.t())
  def get_by_plan_definition(plan_definition_id, limit) do
    query =
      from(plan_execution in PlanExecution,
        where: plan_execution.plan_definition_id == ^plan_definition_id,
        limit: ^limit,
        order_by: [asc: :finished_at],
        select: plan_execution
      )

    Smokex.Repo.all(query)
  end

  @doc """
  Returns all the executions of a plan definition id that are in the given
  status.
  """
  @spec get_by_plan_definition(integer, PlanExecution.status()) :: list(PlanExecution.t())
  def get_by_plan_definition(plan_definition_id, status) do
    query =
      from(plan_execution in PlanExecution,
        where: plan_execution.plan_definition_id == ^plan_definition_id,
        where: plan_execution.status == ^status,
        select: plan_execution
      )

    Smokex.Repo.all(query)
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
  Updates a plan execution as started.
  """
  @spec start(PlanExecution.t()) :: {:ok, PlanExecution.t()} | {:error, term}
  def start(%PlanExecution{} = plan_execution) do
    update_plan_execution(plan_execution, %{status: :running, started_at: NaiveDateTime.utc_now()})
  end

  @doc """
  Finishes a plan execution and sets it as `halted`.
  """
  @spec halt(PlanExecution.t()) :: {:ok, PlanExecution.t()} | {:error, term}
  def halt(%PlanExecution{} = plan_execution) do
    update_plan_execution(plan_execution, %{status: :halted, finished_at: NaiveDateTime.utc_now()})
  end

  @doc """
  Updates a plan execution as finished.
  """
  @spec finish(PlanExecution.t()) :: {:ok, PlanExecution.t()} | {:error, term}
  def finish(%PlanExecution{} = plan_execution) do
    update_plan_execution(plan_execution, %{
      status: :finished,
      finished_at: NaiveDateTime.utc_now()
    })
  end
end
