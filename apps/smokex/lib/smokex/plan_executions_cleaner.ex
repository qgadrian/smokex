defmodule Smokex.PlanExecutionsCleaner do
  @moduledoc """
  Module that provides functions to cleanup plan executions data.
  """

  import Ecto.Query

  alias Smokex.PlanExecution

  @doc """
  Delete executions from all users older than 2 weeks.

  Organizations with PRO access won't get the executions removed.
  """
  @spec clear_old_executions_from_organizations() :: {number_of_deletions :: number, term}
  def clear_old_executions_from_organizations() do
    query =
      from(plan_execution in PlanExecution,
        join: plan_definition in assoc(plan_execution, :plan_definition),
        join: organization in assoc(plan_definition, :organization),
        on: organization.id == plan_definition.organization_id,
        where: fragment("now() - ? > interval '2 weeks'", plan_execution.inserted_at),
        where:
          (not is_nil(organization.subscription_expires_at) and
             fragment("now() - ? > interval '2 days'", organization.subscription_expires_at)) or
            is_nil(organization.subscription_expires_at)
      )

    Smokex.Repo.delete_all(query)
  end
end
