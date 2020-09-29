# TODO refactor to Smokex.PlanDefinitions.PlanDefinition
# TODO same with PlanExecution and others
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
  alias Smokex.Organizations.Organization

  @required_fields [:name, :content]
  @optional_fields [:description, :cron_sentence]

  @schema_fields @optional_fields ++ @required_fields

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "plans_definitions" do
    field(:name, :string, null: false)
    field(:description, :string, null: true)
    field(:cron_sentence, :string, null: true)
    field(:content, :string, null: false)

    belongs_to(:author, User)
    belongs_to(:organization, Organization)

    has_many(:executions, PlanExecution)

    timestamps()
  end

  def create_changeset(changeset, params \\ %{}) do
    author = Map.get(params, :author) || Map.get(params, "author")
    organization = Map.get(params, :organization) || Map.get(params, "organization")

    changeset
    |> Ecto.Changeset.cast(params, @schema_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
    |> Ecto.Changeset.put_assoc(:author, author)
    |> Ecto.Changeset.put_assoc(:organization, organization)
    |> validate_cron_expression()
    |> validate_content()
  end

  def update_changeset(changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @schema_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
    |> validate_cron_expression()
    |> validate_content()
  end

  @spec validate_cron_expression(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_cron_expression(changeset) do
    Ecto.Changeset.validate_change(changeset, :cron_sentence, fn _current_field, value ->
      case Crontab.CronExpression.Parser.parse(value) do
        {:ok, _cron_expression} -> []
        _ -> [{:cron_sentence, "The cron expression is not valid"}]
      end
    end)
  end

  @spec validate_content(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_content(changeset) do
    Ecto.Changeset.validate_change(changeset, :content, fn _current_field, value ->
      case SmokexClient.Parsers.Yaml.Parser.parse(value) do
        {:ok, _parsed_yaml} -> []
        _ -> [{:content, "invalid content please check documentation"}]
      end
    end)
  end
end
