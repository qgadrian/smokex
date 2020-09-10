defmodule Smokex.PlanExecution do
  @moduledoc """
  This module represents the execution of a [plan
  definition](`t:#{PlanDefinition}/0`).
  """

  use Ecto.Schema

  alias Smokex.Result
  alias Smokex.PlanDefinition
  alias Smokex.Users.User
  alias Smokex.Enums.PlanExecutionStatus

  @typedoc """
  The status of an execution:

  * `created`: The execution is created but not started yet.
  * `running`: The execution is currently running.
  * `halted`: The execution is no longer running and didn't finished all the
  steps.
  * `finished`: The execution is finished.
  """
  @type status :: :created | :running | :halted | :finished

  @typedoc """
  Represents a plan execution:

  * `status`: The [status](`t:#{__MODULE__}.status/0`) of the execution.
  * `started_at`: When the execution was started, without timezone.
  * `finished_at`: When the execution was finished, without timezone.
  * `plan_definition`: [action](`t:#{RequestActionEnum}/0`) that was executed.
  * `results`: The total [results](`t:#{RequestResultEnum}/0`) of the
  execution.
  * `user`: The user who the trigger the execution. If the execution was
  executed automatically will be `nil`.
  """
  @type t :: %__MODULE__{
          finished_at: NaiveDateTime.t(),
          plan_definition: PlanDefinition.t(),
          results: list(Result.t()),
          started_at: NaiveDateTime.t(),
          status: status(),
          total_executions: integer,
          user: User.t()
        }

  # @required_fields [:plan_definition_id]
  @required_fields []
  @optional_fields [:status, :started_at, :finished_at, :total_executions]

  @schema_fields @optional_fields ++ @required_fields

  schema "plans_executions" do
    field(:status, PlanExecutionStatus, null: false, default: :created)
    field(:total_executions, :integer, null: true)

    field(:started_at, :naive_datetime, null: true)
    field(:finished_at, :naive_datetime, null: true)

    # TODO rename user to `trigger_by_user`
    belongs_to(:user, User)
    belongs_to(:plan_definition, PlanDefinition)

    has_many(:results, Result)

    timestamps()
  end

  @spec create_changeset(__MODULE__.t(), map) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @schema_fields)
    # |> Ecto.Changeset.validate_required(params, @required_fields)
    |> Ecto.Changeset.put_assoc(
      :plan_definition,
      params[:plan_definition] || changeset.plan_definition
    )
    |> maybe_put_user(params)
    |> Ecto.Changeset.assoc_constraint(:plan_definition)
  end

  @spec update_changeset(__MODULE__.t(), map) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @schema_fields)
  end

  #
  # Private functions
  #

  defp maybe_put_user(changeset, %{user: user}) do
    case user do
      nil ->
        Ecto.Changeset.put_assoc(changeset, :user, nil)

      user ->
        changeset
        |> Ecto.Changeset.put_assoc(:user, user)
        |> Ecto.Changeset.assoc_constraint(:user)
    end
  end
end
