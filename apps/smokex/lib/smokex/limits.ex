defmodule Smokex.Limits do
  @moduledoc """
  This module provides function to track the usage limit of the application.

  ## Scope

  The scope of the limitations affect to users that have a non premium
  subscription only.

  In order to create/execute new resources the organization has to have premium
  access or meet the limited configuration.

  ## Limits

  ### Plan definition limit

  There is a limit of 2 plan definitions per user.

  ### Execution limit

  There is a limit of 1 execution per plan per day. After 24 hours, this limit
  gets removed and the plan can be executed again.
  """

  alias Smokex.PlanDefinition
  alias Smokex.PlanExecution
  alias Smokex.PlanDefinitions
  alias Smokex.Organizations.Organization
  alias Smokex.Users
  alias Smokex.Organizations
  alias Smokex.Users.User

  @max_plan_definitions 2
  @max_daily_executions 10

  @doc """
  Whether a new plan definition can be created or not.
  """
  @spec can_create_plan_definition?(User.t() | nil) :: boolean
  def can_create_plan_definition?(nil), do: false

  def can_create_plan_definition?(%User{} = user) do
    Users.subscribed?(user) || length(PlanDefinitions.all(user)) < @max_plan_definitions
  end

  @doc """
  Returns `true` if a new execution can be started.

  This function can receive a `user`, `plan_execution` or `plan_definition` and
  will check the limits for the related `organization`.

  """
  @spec can_start_execution?(User.t() | PlanExecution.t() | PlanDefinition.t()) :: boolean
  def can_start_execution?(%PlanDefinition{} = plan_definition) do
    %PlanDefinition{organization: %Organization{} = organization} =
      Smokex.Repo.preload(plan_definition, :organization)

    Organizations.subscribed?(organization) ||
      get_daily_executions(organization) < @max_daily_executions
  end

  def can_start_execution?(%User{} = user) do
    {:ok, organization} = Organizations.get_organization(user)

    Organizations.subscribed?(organization) ||
      get_daily_executions(organization) < @max_daily_executions
  end

  @spec can_start_execution?(PlanExecution.t()) :: boolean
  def can_start_execution?(%PlanExecution{} = plan_execution) do
    %PlanExecution{plan_definition: %PlanDefinition{organization: organization}} =
      Smokex.Repo.preload(plan_execution, plan_definition: :organization)

    Organizations.subscribed?(organization) ||
      get_daily_executions(organization) < @max_daily_executions
  end

  @doc """
  Returns the number of executions for the organization for the last 24 hours since
  last execution was started.
  """
  @spec get_daily_executions(Organization.t()) :: integer | nil
  def get_daily_executions(%Organization{id: organization_id}) do
    Cachex.get!(:daily_executions, organization_id) || 0
  end

  @doc """
  Returns the number of executions for the organization for the last 24 hours since
  last execution was started.
  """
  @spec increase_daily_executions(Organization.t() | (organization_id :: integer)) :: :ok
  def increase_daily_executions(%Organization{id: organization_id}) do
    increase_daily_executions(organization_id)
  end

  def increase_daily_executions(organization_id) when is_number(organization_id) do
    count = Cachex.get!(:daily_executions, organization_id) || 0
    Cachex.expire(:daily_executions, organization_id, :timer.hours(24))
    Cachex.put!(:daily_executions, organization_id, count + 1)
  end
end
