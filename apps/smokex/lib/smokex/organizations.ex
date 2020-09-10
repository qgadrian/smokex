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

  @doc """
  Returns whether the organization has an premium access to the application.

  If the organization is not subscribed, then the `free_access` config is
  checked as fallback to grant access to premium features.
  """
  @spec subscribed?(Organization.t()) :: boolean
  def subscribed?(nil) do
    Application.get_env(:smokex, :free_access, false)
  end

  def subscribed?(%Organization{subscription_expires_at: nil}) do
    Application.get_env(:smokex, :free_access, false)
  end

  def subscribed?(%Organization{subscription_expires_at: subscription_expires_at}) do
    is_free_access = Application.get_env(:smokex, :free_access, false)

    if is_free_access do
      true
    else
      subscription_expires_at
      |> DateTime.compare(DateTime.utc_now())
      |> case do
        :gt -> true
        :eq -> true
        :lt -> false
      end
    end
  end
end
