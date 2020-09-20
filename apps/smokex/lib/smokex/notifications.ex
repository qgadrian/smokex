defmodule Smokex.Notifications do
  @moduledoc """
  Handles the notifications in the system.

  So far the following notifications are enabled:

  * Slack
  """

  require Logger

  alias Smokex.PlanExecution
  alias Smokex.PlanDefinition
  alias Smokex.Users.User
  alias Smokex.Notifications.Slack
  alias Smokex.Notifications.Email

  @doc """
  Notifies a change in a execution.

  This function receives and returns a tuple with a result on a
  `t:#{PlanExecution}.t/0` change.
  """
  @spec maybe_notify_change({:ok, PlanExecution.t()} | term) :: {:ok, PlanExecution.t()} | term
  def maybe_notify_change({:ok, %PlanExecution{} = plan_execution} = result) do
    Slack.notify_change(plan_execution)
    Email.notify_change(plan_execution)

    result
  end

  def maybe_notify_change(error), do: error

  @doc """
  Returns the trigger user name to be used on notifications.
  """
  @spec trigger_user(PlanExecution.t()) :: String.t()
  def trigger_user(%PlanExecution{} = plan_execution) do
    case Smokex.Repo.preload(plan_execution, :trigger_user) do
      %PlanExecution{trigger_user: nil} -> "automatic"
      %PlanExecution{trigger_user: %User{email: email}} -> email
    end
  end

  @doc """
  Returns the url for the execution.
  """
  @spec plan_execution_url(PlanExecution.t()) :: String.t()
  def plan_execution_url(%PlanExecution{id: plan_execution_id}) do
    SmokexWeb.Router.Helpers.live_url(
      SmokexWeb.Endpoint,
      SmokexWeb.PlansExecutionsLive.Show,
      plan_execution_id
    )
  end

  @doc """
  Returns the url for the plan definition.
  """
  @spec plan_definition_url(PlanExecution.t()) :: String.t()
  def plan_definition_url(%PlanExecution{} = plan_execution) do
    %PlanExecution{plan_definition: %PlanDefinition{id: plan_definition_id}} =
      Smokex.Repo.preload(plan_execution, :plan_definition)

    SmokexWeb.Router.Helpers.live_url(
      SmokexWeb.Endpoint,
      SmokexWeb.PlansDefinitionsLive.Show,
      plan_definition_id
    )
  end
end
