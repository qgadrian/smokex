defmodule Smokex.Organizations do
  alias Smokex.Users.User
  alias Smokex.Organizations.Organization

  @spec create(name :: String.t(), User.t()) ::
          {:ok, Organization.t()} | {:error, Ecto.Changeset.t()}
  def create(name, %User{} = user) when is_binary(name) do
    %Organization{name: name}
    |> Organization.create_changeset(%{users: [user]})
    |> Smokex.Repo.insert()
  end
end
