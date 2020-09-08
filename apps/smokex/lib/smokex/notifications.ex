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
    %PlanExecution{plan_definition: %PlanDefinition{users: [user]}} =
      plan_execution = Smokex.Repo.preload(plan_execution, plan_definition: :users)

    %User{slack_integration: slack_integration} = Smokex.Repo.preload(user, :slack_integration)

    do_maybe_notify_slack(slack_integration, plan_execution)
  end

  @spec do_maybe_notify_slack(SlackUserIntegration.t(), PlanExecution.t()) :: :ok
  defp do_maybe_notify_slack(nil, _), do: :ok

  defp do_maybe_notify_slack(
         %SlackUserIntegration{} = slack_integration,
         %PlanExecution{
           id: plan_execution_id,
           user: user,
           status: :running,
           started_at: started_at
         } = plan_execution
       ) do
    plan_execution_url = plan_execution_url(plan_execution)
    trigger_user = trigger_user(user)

    SlackHelper.post_message(
      slack_integration,
      "",
      %{
        blocks:
          Jason.encode!([
            %{
              "type" => "section",
              "text" => %{
                "type" => "mrkdwn",
                "text" => "A execution is *running* ⚙️ \n*<#{plan_execution_url}|View execution>*"
              }
            },
            %{
              "type" => "section",
              "fields" => [
                %{"type" => "mrkdwn", "text" => "*Triggered by:*\n#{trigger_user}"},
                %{"type" => "mrkdwn", "text" => "*Started at:*\n#{started_at}"}
              ]
            }
          ])
      }
    )
  end

  defp do_maybe_notify_slack(
         %SlackUserIntegration{} = slack_integration,
         %PlanExecution{
           id: plan_execution_id,
           user: user,
           status: :halted,
           started_at: started_at,
           finished_at: finished_at
         } = plan_execution
       ) do
    plan_execution_url = plan_execution_url(plan_execution)

    SlackHelper.post_message(
      slack_integration,
      "",
      %{
        blocks:
          Jason.encode!([
            %{
              "type" => "section",
              "text" => %{
                "type" => "mrkdwn",
                "text" => "A execution *failed* ❌\n*<#{plan_execution_url}|View execution>*"
              }
            },
            %{
              "type" => "section",
              "fields" => [
                %{"type" => "mrkdwn", "text" => "*Started at:*\n#{started_at}"},
                %{"type" => "mrkdwn", "text" => "*Failed at:*\n#{finished_at}"}
              ]
            }
          ])
      }
    )
  end

  defp do_maybe_notify_slack(
         %SlackUserIntegration{} = slack_integration,
         %PlanExecution{
           id: plan_execution_id,
           user: user,
           status: :finished,
           started_at: started_at,
           finished_at: finished_at
         } = plan_execution
       ) do
    plan_execution_url = "https://smokex.io/executions/#{plan_execution_id}"

    SlackHelper.post_message(
      slack_integration,
      "",
      %{
        blocks:
          Jason.encode!([
            %{
              "type" => "section",
              "text" => %{
                "type" => "mrkdwn",
                "text" => "A execution is *finished* ✅\n*<#{plan_execution_url}|View execution>*"
              }
            },
            %{
              "type" => "section",
              "fields" => [
                %{"type" => "mrkdwn", "text" => "*Started at:*\n#{started_at}"},
                %{"type" => "mrkdwn", "text" => "*Finished at:*\n#{finished_at}"}
              ]
            }
          ])
      }
    )
  end

  @spec plan_execution_url(PlanExecution.t()) :: String.t()
  defp plan_execution_url(%PlanExecution{id: plan_execution_id}),
    do: "https://smokex.io/executions/#{plan_execution_id}"

  @spec trigger_user(nil | User.t()) :: String.t()
  defp trigger_user(nil), do: "automatic"
  defp trigger_user(%User{email: email}), do: email
end
