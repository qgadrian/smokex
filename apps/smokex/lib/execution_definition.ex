defmodule Smokex.ExecutionDefinition do
  use Ecto.Schema

  schema "executions_definitions" do
    field(:name, :string)
    # belongs_to(:user, User)

    # has_many(:result)

    timestamps()
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, [])

    # |> Ecto.Changeset.put_assoc(:user, params[:user])
  end
end
