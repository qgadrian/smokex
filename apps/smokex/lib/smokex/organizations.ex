defmodule Smokex.Organizations do
  alias Smokex.Users.User
  alias Smokex.Organizations.Organization

  @doc """
  Creates a new organization.

  It is required that a organization contains at least one member, therefore in
  order to create a new organization a new user should be provided to be the
  only member.
  """
  @spec create(name :: String.t(), User.t()) ::
          {:ok, Organization.t()} | {:error, Ecto.Changeset.t()}
  def create(name, %User{} = user) when is_binary(name) do
    %Organization{name: name}
    |> Organization.create_changeset(%{users: [user]})
    |> Smokex.Repo.insert()
  end
end
