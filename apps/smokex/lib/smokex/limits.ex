defmodule Smokex.Limits do
  @moduledoc """
  This module provides function to track the usage limit of the application.

  ## Scope

  The scope of the limitations affect to users that have a non premium
  subscription only.

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
  alias Smokex.Users
  alias Smokex.Users.User

  @doc """
  Whether a new plan definition can be created or not.
  """
  @spec can_create_plan_definition?(User.t()) :: boolean
  def can_create_plan_definition?(%User{} = user) do
    Users.subscribed?(user) || length(PlanDefinitions.all(user)) < 2
  end

  @doc """
  Whether the plan definition can start a new execution.

  In order to create a new plan definition the user has to have premium access
  or meet the limited configuration.
  """
  @spec can_start_execution?(User.t(), PlanDefinition.t()) :: boolean
  def can_start_execution?(%User{} = user, %PlanDefinition{} = plan_definition) do
    Users.subscribed?(user) || get_daily_executions(plan_definition) < 3
  end

  @doc """
  Whether a worker can run a job with the plan execution.

  In order to start a new plan execution the user has to have premium access
  or meet the limited configuration.

  TODO replace the `users` logic when `groups` is created
  """
  @spec can_start_execution?(PlanExecution.t()) :: boolean
  def can_start_execution?(%PlanExecution{} = plan_execution) do
    %PlanExecution{plan_definition: %PlanDefinition{users: users} = plan_definition} =
      Smokex.Repo.preload(plan_execution, plan_definition: :users)

    user_subscribed = Enum.any?(users, fn user -> Users.subscribed?(user) end)

    user_subscribed || get_daily_executions(plan_definition) < 3
  end

  @doc """
  Returns the number of executions for the user for the last 24 hours since
  last execution was started.
  """
  @spec get_daily_executions(PlanDefinition.t()) :: integer | nil
  def get_daily_executions(%PlanDefinition{id: plan_definition_id}) do
    Cachex.get!(:daily_executions, plan_definition_id) || 0
  end

  @doc """
  Returns the number of executions for the user for the last 24 hours since
  last execution was started.
  """
  @spec increase_daily_executions(PlanDefinition.t() | (plan_definition_id :: integer)) :: :ok
  def increase_daily_executions(%PlanDefinition{id: plan_definition_id}) do
    increase_daily_executions(plan_definition_id)
  end

  def increase_daily_executions(plan_definition_id) when is_number(plan_definition_id) do
    count = Cachex.get!(:daily_executions, plan_definition_id) || 0
    Cachex.expire(:daily_executions, plan_definition_id, :timer.hours(24))
    Cachex.put!(:daily_executions, plan_definition_id, count + 1)
  end
end
