defmodule Smokex.Organizations.Secret do
  @moduledoc """
  This module represents a secret for a
  [organization](`Smokex.Organizations.Organization`).
  """

  use Ecto.Schema

  alias Smokex.Organizations.Organization

  @schema_fields [:name, :value, :organization_id]

  schema "organizations_secrets" do
    field(:name, :string, null: false)
    field(:value, Smokex.Ecto.EncryptedToken)

    belongs_to(:organization, Organization)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @schema_fields)
    |> Ecto.Changeset.validate_required(@schema_fields)
    |> Ecto.Changeset.cast_assoc(:organization)
    |> Ecto.Changeset.assoc_constraint(:organization)
    |> Ecto.Changeset.unique_constraint([:name, :organization_id])
  end
end