defmodule Smokex.Organizations.Organization do
  @moduledoc """
  This module represents a `organization`.

  A `organization` contains one or more members.

  A premium access subscription it's at the organization level, so all the
  member inside a organization will have the same premium access.
  """

  use Ecto.Schema

  alias Smokex.Users.User
  alias Smokex.PlanDefinition
  alias Smokex.Organizations.OrganizationsUsers
  alias Smokex.Integrations.Slack.SlackIntegration
  alias Smokex.Organizations.Secret

  @type t :: %__MODULE__{
          name: String.t(),
          subscription_expires_at: DateTime.t(),
          users: list(User.t())
        }

  @required_fields [:name]
  @optional_fields [:subscription_expires_at]

  @schema_fields @optional_fields ++ @required_fields

  schema "organizations" do
    field(:name, :string, null: false)
    field(:subscription_expires_at, :utc_datetime, null: true)

    many_to_many(:users, User, join_through: OrganizationsUsers)

    has_one(:slack_integration, SlackIntegration)

    has_many(:plans_definitions, PlanDefinition)
    has_many(:secrets, Secret)

    timestamps()
  end

  def create_changeset(struct, attrs \\ %{}) do
    users = Map.get(attrs, :users, []) || Map.get(attrs, "users", [])

    struct
    |> Ecto.Changeset.cast(attrs, @schema_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
    |> Ecto.Changeset.validate_length(:users, min: 1)
    |> Ecto.Changeset.put_assoc(:users, users)
  end

  # TODO allow update the users of the organization. This will require validate
  # the number of users (minimum of 1) and stuff like that
  def update_changeset(struct, attrs \\ %{}) do
    struct
    |> Ecto.Changeset.cast(attrs, @optional_fields)
  end
end
