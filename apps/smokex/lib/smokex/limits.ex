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
  alias Smokex.Organizations
  alias Smokex.Users.User

  @doc """
  Whether a new plan definition can be created or not.
  """
  @spec can_create_plan_definition?(User.t() | nil) :: boolean
  def can_create_plan_definition?(nil), do: false

  def can_create_plan_definition?(%User{} = user) do
    {:ok, %Organization{} = organization} = Organizations.get_organization(user)

    Organizations.subscribed?(organization) || maxed_out_plan_definitions?(organization)
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

    Organizations.subscribed?(organization) || maxed_out_executions?(organization)
  end

  def can_start_execution?(%User{} = user) do
    {:ok, organization} = Organizations.get_organization(user)

    Organizations.subscribed?(organization) || maxed_out_executions?(organization)
  end

  @spec can_start_execution?(PlanExecution.t()) :: boolean
  def can_start_execution?(%PlanExecution{} = plan_execution) do
    %PlanExecution{plan_definition: %PlanDefinition{organization: organization}} =
      Smokex.Repo.preload(plan_execution, plan_definition: :organization)

    Organizations.subscribed?(organization) || maxed_out_executions?(organization)
  end

  @doc """
  Returns the number of executions for the organization for the last 24 hours since
  last execution was started.
  """
  @spec get_executions_limit_track(Organization.t()) :: integer | nil
  def get_executions_limit_track(%Organization{id: organization_id}) do
    Cachex.get!(:executions_limit_track, organization_id) || 0
  end

  @doc """
  Returns the number of executions for the organization for the last 24 hours since
  last execution was started.
  """
  @spec increase_daily_executions(Organization.t() | (organization_id :: integer)) :: :ok
  def increase_daily_executions(%Organization{id: organization_id}) do
    count = Cachex.get!(:executions_limit_track, organization_id) || 0

    limit_executions_expires_after_hours =
      Application.get_env(:smokex, :limit_executions_expires_after_hours)

    cache_expires_after = :timer.hours(limit_executions_expires_after_hours)

    Cachex.expire(:executions_limit_track, organization_id, cache_expires_after)
    Cachex.put!(:executions_limit_track, organization_id, count + 1)
  end

  #
  # Private functions
  #

  defp maxed_out_executions?(%Organization{} = organization) do
    get_executions_limit_track(organization) <
      Application.get_env(:smokex, :limit_executions_per_period)
  end

  defp maxed_out_plan_definitions?(%Organization{} = organization) do
    length(PlanDefinitions.all(organization)) <
      Application.get_env(:smokex, :limit_plan_definitions_per_organization)
  end
end
