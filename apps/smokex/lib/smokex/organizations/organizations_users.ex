defmodule Smokex.Organizations.OrganizationsUsers do
  @moduledoc """
  Represents a relation between a user and a organization.
  """
  use Ecto.Schema

  alias Smokex.Users.User
  alias Smokex.Organizations.Organization

  schema "organizations_users" do
    belongs_to(:user, User)
    belongs_to(:organization, Organization)

    timestamps()
  end
end
