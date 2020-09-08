defmodule Smokex.Notifications do
  @moduledoc """
  Handles the notifications in the system.

  So far the following notifications are enabled:

  * Slack
  """

  require Logger

  alias Smokex.Integrations.Slack, as: SlackHelper
  alias Smokex.Integrations.Slack.SlackUserIntegration
  alias Smokex.PlanDefinition
  alias Smokex.PlanExecution
  alias Smokex.Users.User

  @doc """
  Notifies a change in a execution.

  This function receives and returns a tuple with a result on a
  `t:#{PlanExecution}.t/0` change.
  """
  @spec maybe_notify_change({:ok, PlanExecution.t()} | term) :: {:ok, PlanExecution.t()} | term
  def maybe_notify_change({:ok, %PlanExecution{} = plan_execution} = result) do
    maybe_notify_slack(plan_execution)

    result
  end

  def maybe_notify_change(error), do: error

  #
  # Private functions
  #

  @spec maybe_notify_slack(PlanExecution.t()) :: :ok
  defp maybe_notify_slack(%PlanExecution{} = plan_execution) do
    %PlanExecution{status: status, plan_definition: %PlanDefinition{users: [user]}} =
      Smokex.Repo.preload(plan_execution, plan_definition: :users)

    %User{slack_integration: slack_integration} = Smokex.Repo.preload(user, :slack_integration)

    do_maybe_notify_slack(slack_integration, status)
  end

  @spec do_maybe_notify_slack(SlackUserIntegration.t(), PlanExecution.status()) :: :ok
  defp do_maybe_notify_slack(nil, _), do: :ok

  defp do_maybe_notify_slack(%SlackUserIntegration{} = slack_integration, :running) do
    SlackHelper.post_message(slack_integration, "The execution running")
  end

  defp do_maybe_notify_slack(%SlackUserIntegration{} = slack_integration, :halted) do
    SlackHelper.post_message(slack_integration, "The execution failed :(")
  end

  defp do_maybe_notify_slack(%SlackUserIntegration{} = slack_integration, :finished) do
    SlackHelper.post_message(slack_integration, "The execution is finish!!!")
  end
end
