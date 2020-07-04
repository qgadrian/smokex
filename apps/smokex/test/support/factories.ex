defmodule Smokex.TestSupport.Factories do
  @moduledoc """
  Factory to create test data for tests.
  """

  alias Smokex.PlanDefinition
  alias Smokex.PlanExecution

  use ExMachina.Ecto, repo: Smokex.Repo

  def plan_definition_factory do
    %PlanDefinition{
      # name: sequence(:name, &"Plan definition number #{&1}"),
      name: "Plan definition",
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
end
