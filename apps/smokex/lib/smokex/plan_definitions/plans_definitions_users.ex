defmodule Smokex.PlansDefinitionsUsers do
  @moduledoc """
  This module represents a relation between a plan definition and a user.
  """
  use Ecto.Schema

  alias Smokex.PlanDefinition
  alias Smokex.Users.User

  schema "plans_definitions_users" do
    belongs_to(:user, User)
    belongs_to(:plan_definition, PlanDefinition)

    timestamps()
  end
end
