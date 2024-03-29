defmodule Smokex.TestSupport.Factories do
  @moduledoc """
  Factory to create test data for tests.
  """

  alias Smokex.Organizations.Organization
  alias Smokex.Organizations.Secret
  alias Smokex.PlanDefinition
  alias Smokex.PlanExecution
  alias Smokex.Results.HTTPRequestResult
  alias Smokex.Users.User
  alias Smokex.Step.Request

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

  def result_factory do
    %HTTPRequestResult{
      action: :get,
      result: :ok,
      failed_assertions: [],
      plan_execution: build(:plan_execution),
      host: sequence(:host, &"host#{&1}.test")
    }
  end

  def request_factory do
    %Request{
      action: :get,
      host: "localhost",
      query: %{},
      body: %{},
      headers: %{},
      opts: []
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
      name: sequence(:name, &"organization_#{&1}"),
      secrets: []
    }
  end

  def organization_secret_factory do
    %Secret{
      name: sequence(:secret_name, &"secret_#{&1}"),
      value: sequence(:value, &"value_#{&1}")
    }
  end
end
