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

  alias Smokex.PlanExecution
  alias Smokex.Users.User

  @required_fields [:name, :cron_sentence, :content]
  @optional_fields [:description]

  @schema_fields @optional_fields ++ @required_fields

  schema "plans_definitions" do
    field(:name, :string, null: false)
    field(:description, :string, null: true)
    field(:cron_sentence, :string, null: false)
    field(:content, :string, null: false)

    many_to_many(:users, User, join_through: "plans_definitions_users")

    has_many(:executions, PlanExecution)

    timestamps()
  end

  def create_changeset(changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @schema_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
    |> Ecto.Changeset.put_assoc(:users, params[:users])
    |> validate_cron_expression()
  end

  def update_changeset(changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @schema_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
    |> validate_cron_expression()
  end

  @spec validate_cron_expression(Ecto.Changeset.t()) :: keyword
  defp validate_cron_expression(changeset) do
    Ecto.Changeset.validate_change(changeset, :cron_sentence, fn _current_field, value ->
      case Crontab.CronExpression.Parser.parse(value) do
        {:ok, _cron_expression} -> []
        _ -> [{:cron_sentence, "The cron expression is not valid"}]
      end
    end)
  end
end
