defmodule Smokex.PlanExecutionsCleanerTest do
  use ExUnit.Case, async: true
  use Smokex.DataCase

  import Smokex.TestSupport.Factories

  alias Smokex.PlanExecutionsCleaner
  alias Smokex.PlanExecution

  describe "clear_old_executions_from_organizations/1" do
    test "does not clean any execution for organization with PRO" do
      organization =
        insert(:organization,
          subscription_expires_at: DateTime.from_naive!(~N[2099-05-24 13:26:08.003], "Etc/UTC")
        )

      three_weeks_ago = Timex.shift(DateTime.utc_now(), weeks: -3)

      plan_definition = insert(:plan_definition, organization: organization)

      insert(:plan_execution, plan_definition: plan_definition, inserted_at: three_weeks_ago)
      insert(:plan_execution, plan_definition: plan_definition)

      assert Smokex.Repo.aggregate(PlanExecution, :count) == 2

      assert {0, nil} = PlanExecutionsCleaner.clear_old_executions_from_organizations()

      assert Smokex.Repo.aggregate(PlanExecution, :count) == 2
    end

    test "deletes executions older than 2 weeks for organization without PRO" do
      organization = insert(:organization)

      three_weeks_ago = Timex.shift(DateTime.utc_now(), weeks: -3)
      one_week_ago = Timex.shift(DateTime.utc_now(), weeks: -1)

      plan_definition = insert(:plan_definition, organization: organization)

      insert(:plan_execution, plan_definition: plan_definition, inserted_at: three_weeks_ago)
      insert(:plan_execution, plan_definition: plan_definition, inserted_at: three_weeks_ago)
      insert(:plan_execution, plan_definition: plan_definition, inserted_at: one_week_ago)
      insert(:plan_execution, plan_definition: plan_definition)

      assert Smokex.Repo.aggregate(PlanExecution, :count) == 4

      assert {3, nil} = PlanExecutionsCleaner.clear_old_executions_from_organizations()

      assert Smokex.Repo.aggregate(PlanExecution, :count) == 1
    end
  end
end
