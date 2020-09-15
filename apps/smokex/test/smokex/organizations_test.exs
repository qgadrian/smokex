defmodule Smokex.OrganizationsTest do
  use ExUnit.Case, async: true
  use Smokex.DataCase

  import Smokex.TestSupport.Factories

  alias Smokex.Organizations

  describe "get_organization/1" do
    test "raises an error if user is nil" do
      assert_raise FunctionClauseError, fn ->
        Organizations.get_organization(nil)
      end
    end

    test "returns a tuple with the unique organization" do
      organization = insert(:organization)
      user = insert(:user, organizations: [organization])

      assert {:ok, ^organization} = Organizations.get_organization(user)
    end

    test "returns a tuple with an error if the user has multiple organizations" do
      organization_1 = insert(:organization)
      organization_2 = insert(:organization)
      user = insert(:user, organizations: [organization_1, organization_2])

      assert {:error, "multiple organizations not supported yet"} =
               Organizations.get_organization(user)
    end

    test "returns a tuple with an error if the user has no organizations" do
      user = insert(:user, organizations: [])

      assert {:error, "user does not belong to a organization"} =
               Organizations.get_organization(user)
    end
  end

  describe "subscribed?/1" do
    setup do
      on_exit(fn ->
        Application.put_env(:smokex, :free_access, false)
      end)

      :ok
    end

    test "returns true if `free_access` is set to true" do
      organization = insert(:organization)

      Application.put_env(:smokex, :free_access, false)

      refute Organizations.subscribed?(organization)

      Application.put_env(:smokex, :free_access, true)

      assert Organizations.subscribed?(organization)
    end

    test "returns true if organization has a PRO subscription" do
      organization =
        insert(:organization,
          subscription_expires_at: DateTime.from_naive!(~N[2099-05-24 13:26:08.003], "Etc/UTC")
        )

      assert Organizations.subscribed?(organization)
    end

    test "returns false if organization does not have a PRO subscription" do
      organization = insert(:organization, subscription_expires_at: nil)

      refute Organizations.subscribed?(organization)
    end
  end
end
