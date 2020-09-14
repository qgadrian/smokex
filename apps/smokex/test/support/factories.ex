defmodule Smokex.TestSupport.Factories do
  @moduledoc """
  Factory to create test data for tests.
  """

  alias Smokex.Organizations.Organization
  alias Smokex.PlanDefinition
  alias Smokex.PlanExecution
  alias Smokex.Users.User

  use ExMachina.Ecto, repo: Smokex.Repo

  def plan_definition_factory do
    %PlanDefinition{
      # name: sequence(:name, &"Plan definition number #{&1}"),
      name: "Plan definition",
      author: build(:user),
      organization: build(:organization),
      cron_sentence: "* * * * *",
      content: "",
      executions: []
    }
  end

  def plan_execution_factory do
    %PlanExecution{
      status: :created,
      plan_definition: build(:plan_definition),
      results: []
    }
  end

  def user_factory do
    %User{
      email: sequence(:email, &"email#{&1}@test.com"),
      organizations: insert_list(1, :organization)
    }
  end

  def organization_factory do
    %Organization{
      name: sequence(:name, &"organization_#{&1}")
    }
  end
end
