defmodule SmokexClient.ExecutionContextTest do
  use ExUnit.Case, async: true

  import Smokex.TestSupport.Factories

  alias SmokexClient.ExecutionContext

  describe "new/1" do
    test "contains the default values" do
      secrets = []
      organization = insert(:organization, secrets: secrets)
      plan_definition = insert(:plan_definition, organization: organization)
      plan_execution = insert(:plan_execution, plan_definition: plan_definition)

      assert %ExecutionContext{halt_on_error: true} == ExecutionContext.new(plan_execution)
    end

    test "returns a new execution context" do
      secrets = [
        build(:organization_secret, name: "secret_1", value: "23"),
        build(:organization_secret, name: "secret_2", value: "true"),
        build(:organization_secret, name: "secret_3", value: "a secret")
      ]

      organization = insert(:organization, secrets: secrets)
      plan_definition = insert(:plan_definition, organization: organization)
      plan_execution = insert(:plan_execution, plan_definition: plan_definition)

      assert %ExecutionContext{
               halt_on_error: false,
               variables: %{"secret_1" => 23, "secret_2" => true, "secret_3" => "a secret"}
             } ==
               ExecutionContext.new(plan_execution, halt: false)
    end
  end
end
