defmodule Smokex.Notifications.Slack do
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
  alias Smokex.Notifications
  alias Smokex.PlanExecution

  @doc """
  Notifies a change in Slack.

  In order to send the Slack message the organization has the integration
  configured and enabled.
  """
  @spec notify_change(PlanExecution.t()) :: :ok
  def notify_change(%PlanExecution{} = plan_execution) do
    %PlanExecution{plan_definition: %PlanDefinition{organization: organization}} =
      plan_execution = Smokex.Repo.preload(plan_execution, plan_definition: :organization)

    with {:ok, %SlackIntegration{} = slack_integration} <-
           SlackHelper.get_integration(organization) do
      maybe_notify_change(slack_integration, plan_execution)
    end
  end

  @spec maybe_notify_change(SlackIntegration.t(), PlanExecution.t()) :: :ok
  defp maybe_notify_change(
         %SlackIntegration{options: %SlackIntegrationPreferences{post_on_run: true}} =
           slack_integration,
         %PlanExecution{
           status: :running,
           started_at: started_at
         } = plan_execution
       ) do
    plan_execution_url = Notifications.plan_execution_url(plan_execution)
    plan_definition_url = Notifications.plan_definition_url(plan_execution)
    trigger_user = Notifications.trigger_user(plan_execution)

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
                "text" => "An execution is running ⚙️"
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

  defp maybe_notify_change(
         %SlackIntegration{options: %SlackIntegrationPreferences{post_on_fail: true}} =
           slack_integration,
         %PlanExecution{
           status: :halted,
           started_at: started_at,
           finished_at: finished_at
         } = plan_execution
       ) do
    plan_execution_url = Notifications.plan_execution_url(plan_execution)
    plan_definition_url = Notifications.plan_definition_url(plan_execution)
    trigger_user = Notifications.trigger_user(plan_execution)

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
                "text" => "An execution failed ❌"
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

  defp maybe_notify_change(
         %SlackIntegration{options: %SlackIntegrationPreferences{post_on_success: true}} =
           slack_integration,
         %PlanExecution{
           status: :finished,
           started_at: started_at,
           finished_at: finished_at
         } = plan_execution
       ) do
    plan_execution_url = Notifications.plan_execution_url(plan_execution)
    plan_definition_url = Notifications.plan_definition_url(plan_execution)
    trigger_user = Notifications.trigger_user(plan_execution)

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
                "text" => "An execution is finished ✅"
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

  defp maybe_notify_change(_, _), do: :ok
end
