defmodule Smokex.OrganizationsSecrets do
  @moduledoc """
  Context module to provide functions to work with Plan definition secrets.
  """

  alias Smokex.Organizations.Organization
  alias Smokex.Organizations.Secret

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

  @spec get(Organization.t) :: list(Secrets.t)
  def get(%Organization{} = organization) do
    Smokex.Repo.preload(organization, :secrets).secrets
  end
end
