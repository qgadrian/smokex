defmodule Smokex.PlanDefinitionsTest do
  use ExUnit.Case, async: true
  use Smokex.DataCase

  import Smokex.TestSupport.Factories

  alias Smokex.PlanDefinitions
  alias Smokex.PlanDefinition
  alias Smokex.PlanExecution

  describe "all/1" do
    test "returns an empty list if organization or user is nil" do
      assert PlanDefinitions.all(nil) == []
    end

    test "returns the plan definitions for the user organization" do
      organization = insert(:organization)
      user = insert(:user, organizations: [organization])

      %PlanDefinition{id: plan_definition_1} =
        insert(:plan_definition, organization: organization)

      %PlanDefinition{id: plan_definition_2} =
        insert(:plan_definition, organization: organization)

      assert [
               %PlanDefinition{id: ^plan_definition_2},
               %PlanDefinition{id: ^plan_definition_1}
             ] = PlanDefinitions.all(user)
    end

    test "returns the plan definitions for the organization" do
      organization = insert(:organization)

      %PlanDefinition{id: plan_definition_1} =
        insert(:plan_definition, organization: organization)

      %PlanDefinition{id: plan_definition_2} =
        insert(:plan_definition, organization: organization)

      # Check why the order differs from the test above
      assert [
               %PlanDefinition{id: ^plan_definition_1},
               %PlanDefinition{id: ^plan_definition_2}
             ] = PlanDefinitions.all(organization)
    end
  end

  describe "preload_last_execution/1" do
    test "preloads the last execution" do
      plan_definition = insert(:plan_definition)

      %PlanExecution{id: last_plan_execution_id} =
        insert(:plan_execution, plan_definition: plan_definition)

      insert(:plan_execution, plan_definition: plan_definition)
      insert(:plan_execution, plan_definition: plan_definition)

      plan_definition = Smokex.Repo.get(PlanDefinition, plan_definition.id)

      assert %PlanDefinition{executions: %Ecto.Association.NotLoaded{}} = plan_definition

      plan_definition = PlanDefinitions.preload_last_execution(plan_definition)

      assert %PlanDefinition{executions: [%PlanExecution{id: ^last_plan_execution_id}]} =
               plan_definition
    end
  end

  describe "subscribe/1" do
    test "subscribes the process to the plan definition id topic" do
      plan_definition = insert(:plan_definition)

      PlanDefinitions.subscribe(plan_definition)

      Phoenix.PubSub.broadcast(
        Smokex.PubSub,
        "#{plan_definition.id}",
        "a test message"
      )

      assert_received "a test message"
    end
  end
end
