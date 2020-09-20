defmodule Smokex.Notifications.Email do
  @moduledoc """
  This module handles email notifications for executions.
  """

  alias Smokex.Organizations.Organization
  alias Smokex.PlanDefinition
  alias Smokex.PlanExecution
  alias Smokex.Notifications
  alias Smokex.Users.User

  @from_email "notifications@smokex.io"

  @doc """
  Notifies a execution change via email.
  """
  @spec notify_change(PlanExecution.t()) :: :ok
  def notify_change(%PlanExecution{} = plan_execution) do
    %PlanExecution{
      started_at: plan_execution_started_at,
      status: plan_execution_status,
      plan_definition: %PlanDefinition{
        name: plan_definition_name,
        organization: %Organization{users: users}
      }
    } = Smokex.Repo.preload(plan_execution, plan_definition: [organization: :users])

    assigns = %{
      plan_execution_url: Notifications.plan_execution_url(plan_execution),
      plan_definition_name: plan_definition_name,
      start_date: plan_execution_started_at,
      status: plan_execution_status,
      trigger_user: Notifications.trigger_user(plan_execution)
    }

    if Application.get_env(:smokex, :enable_email_notifications) do
      Enum.each(users, fn
        %User{} = user ->
          %{
            user: user,
            subject: "Execution #{plan_execution_status}",
            template: "execution_update.html"
          }
          |> SmokexWeb.Pow.Mailer.cast(from: @from_email, assigns: assigns)
          |> SmokexWeb.Pow.Mailer.process()
      end)
    else
      :ok
    end
  end
end
