defmodule Smokex.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema

  @optional_fields [:subscription_expires_at]

  @schema_fields @optional_fields

  schema "users" do
    field(:subscription_expires_at, :utc_datetime)

    pow_user_fields()

    timestamps()
  end

  # TODO as in other modules, change this to `create_changeset`
  def changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_changeset(attrs)
    |> Ecto.Changeset.cast(attrs, @schema_fields)
  end

  def update_changeset(changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @schema_fields)
  end
end
