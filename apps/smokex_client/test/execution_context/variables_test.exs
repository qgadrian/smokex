defmodule SmokexClient.ExecutionContext.VariablesTest do
  use ExUnit.Case, async: true

  import Smokex.TestSupport.Factories

  alias SmokexClient.ExecutionContext.Variables

  describe "from_organization_secrets/1" do
    test "returns an empty list when the organization of the execution has no secrets" do
      organization = insert(:organization)
      user = insert(:user, organizations: [organization])
      plan_definition = insert(:plan_definition, author: user, organization: organization)
      plan_execution = insert(:plan_execution, plan_definition: plan_definition)

      assert %{} == Variables.from_organization_secrets(plan_execution)
    end

    test "returns a map with the organization secrets" do
      secrets = [
        build(:organization_secret, name: "secret_1", value: "23"),
        build(:organization_secret, name: "secret_2", value: "jk43gnkgf")
      ]

      organization = insert(:organization, secrets: secrets)
      user = insert(:user, organizations: [organization])
      plan_definition = insert(:plan_definition, author: user, organization: organization)
      plan_execution = insert(:plan_execution, plan_definition: plan_definition)

      assert %{
               "secret_1" => 23,
               "secret_2" => "jk43gnkgf"
             } == Variables.from_organization_secrets(plan_execution)
    end

    test "converts the secrets to the correct type" do
      secrets = [
        build(:organization_secret, name: "secret_1", value: "23"),
        build(:organization_secret, name: "secret_2", value: "jk43gnkgf"),
        build(:organization_secret, name: "secret_3", value: "true"),
        build(:organization_secret, name: "secret_4", value: "jk43gnkgf"),
        build(:organization_secret, name: "secret_5", value: "false"),
        build(:organization_secret, name: "secret_6", value: "asdfasdasdasd")
      ]

      organization = insert(:organization, secrets: secrets)
      user = insert(:user, organizations: [organization])
      plan_definition = insert(:plan_definition, author: user, organization: organization)
      plan_execution = insert(:plan_execution, plan_definition: plan_definition)

      assert %{
               "secret_1" => 23,
               "secret_2" => "jk43gnkgf",
               "secret_3" => true,
               "secret_4" => "jk43gnkgf",
               "secret_5" => false,
               "secret_6" => "asdfasdasdasd"
             } == Variables.from_organization_secrets(plan_execution)
    end
  end
end
