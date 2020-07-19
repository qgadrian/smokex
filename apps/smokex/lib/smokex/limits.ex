defmodule Smokex.Limits do
  alias Smokex.PlanDefinition
  alias Smokex.Users.User
  alias Smokex.Users

  @doc """
  Whether the plan definition can start a new execution.

  In order to create a new plan definition the user has to have premium access
  or meet the limited configuration.
  """
  @spec can_start_execution?(User.t(), PlanDefinition.t()) :: boolean
  def can_start_execution?(%User{} = user, %PlanDefinition{} = plan_definition) do
    Users.subscribed?(user) || get_daily_executions(plan_definition) < 1
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
