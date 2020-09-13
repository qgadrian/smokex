defmodule Smokex.Notifications do
  @moduledoc """
  Handles the notifications in the system.

  So far the following notifications are enabled:

  * Slack
  """

  require Logger

  alias Smokex.Integrations.Slack, as: SlackHelper
  alias Smokex.Integrations.Slack.SlackIntegration
  alias Smokex.Integrations.Slack.SlackIntegrationPreferences
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
    %PlanExecution{plan_definition: %PlanDefinition{organization: organization}} =
      plan_execution = Smokex.Repo.preload(plan_execution, plan_definition: :organization)

    with {:ok, %SlackIntegration{} = slack_integration} <-
           SlackHelper.get_integration(organization) do
      do_maybe_notify_slack(slack_integration, plan_execution)
    end
  end

  @spec do_maybe_notify_slack(SlackIntegration.t(), PlanExecution.t()) :: :ok
  defp do_maybe_notify_slack(
         %SlackIntegration{options: %SlackIntegrationPreferences{post_on_run: true}} =
           slack_integration,
         %PlanExecution{
           status: :running,
           started_at: started_at
         } = plan_execution
       ) do
    plan_execution_url = plan_execution_url(plan_execution)
    plan_definition_url = plan_definition_url(plan_execution)
    trigger_user = trigger_user(plan_execution)

    SlackHelper.post_message(
      slack_integration,
      "",
      %{
        blocks:
          Jason.encode!([
            %{
              "type" => "header",
              "text" => %{
                "type" => "plain_text",
                "text" => "A execution is running ⚙️"
              }
            },
            %{
              "type" => "context",
              "elements" => [
                %{
                  "text" => "Started *#{started_at}* | by *#{trigger_user}*",
                  "type" => "mrkdwn"
                }
              ]
            },
            %{
              "type" => "actions",
              "elements" => [
                %{
                  "type" => "button",
                  "text" => %{
                    "type" => "plain_text",
                    "text" => "View execution",
                    "emoji" => true
                  },
                  "url" => "#{plan_execution_url}"
                },
                %{
                  "type" => "button",
                  "text" => %{
                    "type" => "plain_text",
                    "text" => "View plan",
                    "emoji" => true
                  },
                  "url" => "#{plan_definition_url}"
                }
              ]
            }
          ])
      }
    )
  end

  defp do_maybe_notify_slack(
         %SlackIntegration{options: %SlackIntegrationPreferences{post_on_fail: true}} =
           slack_integration,
         %PlanExecution{
           status: :halted,
           started_at: started_at,
           finished_at: finished_at
         } = plan_execution
       ) do
    plan_execution_url = plan_execution_url(plan_execution)
    plan_definition_url = plan_definition_url(plan_execution)
    trigger_user = trigger_user(plan_execution)

    SlackHelper.post_message(
      slack_integration,
      "",
      %{
        blocks:
          Jason.encode!([
            %{
              "type" => "header",
              "text" => %{
                "type" => "plain_text",
                "text" => "A execution failed ❌"
              }
            },
            %{
              "type" => "context",
              "elements" => [
                %{
                  "text" => "Started *#{started_at}* | by *#{trigger_user}*",
                  "type" => "mrkdwn"
                }
              ]
            },
            %{
              "type" => "context",
              "elements" => [
                %{
                  "text" => "Failed at *#{finished_at}*",
                  "type" => "mrkdwn"
                }
              ]
            },
            %{
              "type" => "actions",
              "elements" => [
                %{
                  "type" => "button",
                  "text" => %{
                    "type" => "plain_text",
                    "text" => "View execution",
                    "emoji" => true
                  },
                  "style" => "danger",
                  "url" => "#{plan_execution_url}"
                },
                %{
                  "type" => "button",
                  "text" => %{
                    "type" => "plain_text",
                    "text" => "View plan",
                    "emoji" => true
                  },
                  "url" => "#{plan_definition_url}"
                }
              ]
            }
          ])
      }
    )
  end

  defp do_maybe_notify_slack(
         %SlackIntegration{options: %SlackIntegrationPreferences{post_on_success: true}} =
           slack_integration,
         %PlanExecution{
           status: :finished,
           started_at: started_at,
           finished_at: finished_at
         } = plan_execution
       ) do
    plan_execution_url = plan_execution_url(plan_execution)
    plan_definition_url = plan_definition_url(plan_execution)
    trigger_user = trigger_user(plan_execution)

    SlackHelper.post_message(
      slack_integration,
      "",
      %{
        blocks:
          Jason.encode!([
            %{
              "type" => "header",
              "text" => %{
                "type" => "plain_text",
                "text" => "A execution is finished ✅"
              }
            },
            %{
              "type" => "context",
              "elements" => [
                %{
                  "text" => "Started *#{started_at}* | by *#{trigger_user}*",
                  "type" => "mrkdwn"
                }
              ]
            },
            %{
              "type" => "context",
              "elements" => [
                %{
                  "text" => "Finished at *#{finished_at}*",
                  "type" => "mrkdwn"
                }
              ]
            },
            %{
              "type" => "actions",
              "elements" => [
                %{
                  "type" => "button",
                  "text" => %{
                    "type" => "plain_text",
                    "text" => "View execution",
                    "emoji" => true
                  },
                  "style" => "primary",
                  "url" => "#{plan_execution_url}"
                },
                %{
                  "type" => "button",
                  "text" => %{
                    "type" => "plain_text",
                    "text" => "View plan",
                    "emoji" => true
                  },
                  "url" => "#{plan_definition_url}"
                }
              ]
            }
          ])
      }
    )
  end

  defp do_maybe_notify_slack(_, _), do: :ok

  @spec plan_execution_url(PlanExecution.t()) :: String.t()
  defp plan_execution_url(%PlanExecution{id: plan_execution_id}),
    do: "https://smokex.io/executions/#{plan_execution_id}"

  @spec plan_definition_url(PlanExecution.t()) :: String.t()
  defp plan_definition_url(%PlanExecution{} = plan_execution) do
    %PlanExecution{plan_definition: %PlanDefinition{id: plan_definition_id}} =
      Smokex.Repo.preload(plan_execution, :plan_definition)

    "https://smokex.io/plans/#{plan_definition_id}"
  end

  @spec trigger_user(PlanExecution.t()) :: String.t()
  defp trigger_user(%PlanExecution{} = plan_execution) do
    case Smokex.Repo.preload(plan_execution, :trigger_user) do
      %PlanExecution{trigger_user: nil} -> "automatic"
      %PlanExecution{trigger_user: %User{email: email}} -> email
    end
  end
end
