defmodule Smokex.Organizations do
  @moduledoc """
  Context module that provides functions to work with
  [Organizations](`t:Smokex.Organizations.Organization.t/0`).
  """

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
  Updates an organization.

  ## Examples
      iex> update(organization, %{name: "test"})
      {:ok, %Organization{}}
      iex> update(organization, %{name: nil})
      {:error, %Ecto.Changeset{}}
  """
  @spec update(Organization.t(), map) :: {:ok, Organization.t()} | {:error, Ecto.Changeset.t()}
  def update(%Organization{} = organization, params) when is_map(params) do
    organization
    |> Organization.update_changeset(params)
    |> Smokex.Repo.update()
  end

  @doc """
  Returns the organization the user belongs to.

  If the user belongs to multiple or no organization at all, an error is
  returned.
  """
  @spec get_organization(User.t()) :: {:ok, Organization.t()} | {:error, String.t()}
  def get_organization(%User{} = user) do
    user
    |> Smokex.Repo.preload(:organizations)
    |> case do
      %User{organizations: [%Organization{} = organization]} ->
        {:ok, organization}

      %User{organizations: [%Organization{} | _]} ->
        {:error, "multiple organizations not supported yet"}

      %User{organizations: nil} ->
        {:error, "user does not belong to a organization"}
    end
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
