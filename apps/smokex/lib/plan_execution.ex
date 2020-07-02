defmodule Smokex.PlanExecution do
  @moduledoc """
  This module represents the execution of a [plan
  definition](`t:#{PlanDefinition}/0`).
  """

  use Ecto.Schema

  alias Smokex.Result
  alias Smokex.PlanDefinition
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
  Represents a [plan definition](`t:#{PlanDefinition}/0`):

  * `status`: The [status](`t:#{__MODULE__}.status/0`) of the execution.
  * `plan_definition`: [action](`t:#{RequestActionEnum}/0`) that was executed.
  * `results`: The total [results](`t:#{RequestResultEnum}/0`) of the
  execution.
  """
  @type t :: %__MODULE__{
          status: status(),
          plan_definition: PlanDefinition.t(),
          results: list(Result.t())
        }

  @optional_fields [:status]

  schema "plans_executions" do
    field(:status, PlanExecutionStatus, null: false, default: :created)

    belongs_to(:plan_definition, PlanDefinition)

    has_many(:results, Result, on_replace: :delete)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @optional_fields)
    |> Ecto.Changeset.put_assoc(:plan_definition, params[:plan_definition])
    |> Ecto.Changeset.assoc_constraint(:plan_definition)
  end
end
