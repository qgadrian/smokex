defmodule Smokex.Organizations.Organization do
  use Ecto.Schema

  alias Smokex.Users.User
  alias Smokex.Organizations.OrganizationsUsers

  @required_fields [:name]
  @optional_fields [:subscription_expires_at]

  @schema_fields @optional_fields ++ @required_fields

  schema "organizations" do
    field(:name, :string, null: false)
    field(:subscription_expires_at, :utc_datetime, null: true)

    many_to_many(:users, User, join_through: OrganizationsUsers)

    timestamps()
  end

  def create_changeset(struct, attrs \\ %{}) do
    users = Map.get(attrs, :users, []) || Map.get(attrs, "users", [])

    struct
    |> Ecto.Changeset.cast(attrs, @schema_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
    |> Ecto.Changeset.put_assoc(:users, users)
  end
end
