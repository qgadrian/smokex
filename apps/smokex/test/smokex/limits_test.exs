defmodule Smokex.LimitsTest do
  use ExUnit.Case, async: true
  use Smokex.DataCase

  import Smokex.TestSupport.Factories

  alias Smokex.Limits

  describe "can_create_plan_definition?/1" do
    test "returns false when user is nil" do
      refute Limits.can_create_plan_definition?(nil)
    end

    test "returns true until has reached the limit" do
      organization = insert(:organization)
      user = insert(:user, organizations: [organization])

      configured_limit = Application.get_env(:smokex, :limit_plan_definitions_per_organization)

      for _ <- 1..(configured_limit - 1) do
        insert(:plan_definition, organization: organization)

        assert Limits.can_create_plan_definition?(user)
      end

      insert(:plan_definition, organization: organization)

      refute Limits.can_create_plan_definition?(user)
    end
  end

  describe "can_start_execution?/1" do
    setup do
      on_exit(fn ->
        Application.put_env(:smokex, :free_access, false)
        Application.put_env(:smokex, :limit_executions_per_period, 5)
      end)

      :ok
    end

    test "returns true if `free_access` is set to true" do
      user = insert(:user)
      plan_definition = insert(:plan_definition)
      plan_execution = insert(:plan_execution, plan_definition: plan_definition)

      Application.put_env(:smokex, :free_access, false)
      Application.put_env(:smokex, :limit_executions_per_period, 0)

      refute Limits.can_start_execution?(user)
      refute Limits.can_start_execution?(plan_definition)
      refute Limits.can_start_execution?(plan_execution)

      Application.put_env(:smokex, :free_access, true)

      assert Limits.can_start_execution?(user)
      assert Limits.can_start_execution?(plan_definition)
      assert Limits.can_start_execution?(plan_execution)
    end

    test "returns true if organization has a PRO subscription" do
      organization =
        insert(:organization,
          subscription_expires_at: DateTime.from_naive!(~N[2099-05-24 13:26:08.003], "Etc/UTC")
        )

      user = insert(:user)
      plan_definition = insert(:plan_definition, organization: organization)
      plan_execution = insert(:plan_execution, plan_definition: plan_definition)

      assert Limits.can_start_execution?(user)
      assert Limits.can_start_execution?(plan_definition)
      assert Limits.can_start_execution?(plan_execution)
    end

    test "returns true until has reached the limit" do
      organization = insert(:organization)
      user = insert(:user, organizations: [organization])
      plan_definition = insert(:plan_definition, organization: organization)
      plan_execution = insert(:plan_execution, plan_definition: plan_definition)

      configured_limit = Application.get_env(:smokex, :limit_executions_per_period)

      for count <- 1..(configured_limit - 1) do
        Cachex.put!(:executions_limit_track, organization.id, count)

        assert Limits.can_start_execution?(user)
        assert Limits.can_start_execution?(plan_definition)
        assert Limits.can_start_execution?(plan_execution)
      end

      Cachex.put!(:executions_limit_track, organization.id, configured_limit)

      refute Limits.can_start_execution?(user)
      refute Limits.can_start_execution?(plan_definition)
      refute Limits.can_start_execution?(plan_execution)
    end
  end

  describe "increase_daily_executions/1" do
    test "increases the limit counter for the organization" do
      organization = insert(:organization)

      assert Cachex.get!(:executions_limit_track, organization.id) == nil

      for counter <- 1..10 do
        Limits.increase_daily_executions(organization)

        assert Cachex.get!(:executions_limit_track, organization.id) == counter
      end
    end
  end
end
