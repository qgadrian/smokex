defmodule Smokex.OrganizationsSecrets do
  @moduledoc """
  Context module to provide functions to work with Plan definition secrets.
  """

  import Ecto.Query

  alias Smokex.Organizations.Organization
  alias Smokex.Organizations.Secret

  @doc """
  Creates a new organization secret.
  """
  @spec create(Organization.t(), map) :: Secret.t()
  def create(%Organization{id: organization_id}, %{"name" => name, "value" => value}) do
    %Secret{}
    |> Secret.changeset(%{
      organization_id: organization_id,
      name: name,
      value: value
    })
    |> Smokex.Repo.insert()
  end

  @doc """
  Updates a organization secret value.
  """
  @spec update(Secret.t(), map) :: Secret.t()
  def update(%Secret{} = secret, %{"value" => value}) do
    secret
    |> Secret.changeset(%{
      value: value
    })
    |> Smokex.Repo.update()
  end

  @doc """
  Deletes a organization secret.
  """
  @spec delete(Secret.t()) :: {:ok, Secret.t()} | {:error, Ecto.Changeset.t()}
  def delete(%Secret{} = secret) do
    Smokex.Repo.delete(secret)
  end

  @doc """
  Returns the secret for the given organization.

  If the secret is not found or does not belong to the organization, raises an
  error.
  """
  @spec get!(Organization.t(), integer) :: Secret.t() | nil
  def get!(%Organization{id: organization_id}, secret_id) when is_number(secret_id) do
    query =
      from(secret in Secret,
        where: secret.organization_id == ^organization_id,
        where: secret.id == ^secret_id,
        select: secret
      )

    Smokex.Repo.one!(query)
  end

  @doc """
  Returns all secrets of the given organization.
  """
  @spec list(Organization.t()) :: list(Secret.t())
  def list(%Organization{} = organization) do
    Smokex.Repo.preload(organization, :secrets).secrets
  end
end
