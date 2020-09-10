defmodule Smokex.Users.User do
  @moduledoc """
  Represents a user in the application.
  """

  use Ecto.Schema
  use Pow.Ecto.Schema
  use Pow.Extension.Ecto.Schema, extensions: [PowResetPassword, PowEmailConfirmation]

  alias Smokex.Integrations.Slack.SlackUserIntegration
  alias Smokex.PlanDefinition
  alias Smokex.Organizations.Organization
  alias Smokex.Organizations.OrganizationsUsers

  @optional_fields [:subscription_expires_at]

  @schema_fields @optional_fields

  schema "users" do
    field(:subscription_expires_at, :utc_datetime)

    pow_user_fields()

    has_one(:slack_integration, SlackUserIntegration)

    has_many(:plans_definitions, PlanDefinition, foreign_key: :author_id)

    many_to_many(:organizations, Organization, join_through: OrganizationsUsers)

    timestamps()
  end

  def changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_changeset(attrs)
    |> pow_extension_changeset(attrs)
    |> Ecto.Changeset.cast(attrs, @schema_fields)
  end

  def update_changeset(changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @schema_fields)
  end
end
