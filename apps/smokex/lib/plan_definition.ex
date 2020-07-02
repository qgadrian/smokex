defmodule Smokex.PlanDefinition do
  @moduledoc """
  This module represents a plan definition.

  ## Plan definition

  The plan definition consists in a sequence of steps. Each step contains an
  action, a list of asserts and a variable assignments (optional).

  ## Executions

  Each plan definition can be executed several times. Each execution will
  generate a new [execution](`t:#{PlanExecution}.t/0`) entry in the database,
  that will generate results for each step.

  There is no limit of executions for a plan definition.

  TODO add a limit for non PRO users.
  """
  use Ecto.Schema

  alias Smokex.Result
  alias Smokex.PlanExecution

  @required_fields [:name]

  schema "plans_definitions" do
    field(:name, :string)

    # belongs_to(:user, User)

    has_many(:executions, PlanExecution, on_replace: :delete)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @required_fields)
    |> Ecto.Changeset.validate_required(@required_fields)

    # |> Ecto.Changeset.put_assoc(:user, params[:user])
  end
end
