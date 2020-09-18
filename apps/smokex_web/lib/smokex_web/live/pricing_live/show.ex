defmodule SmokexWeb.PricingLive.Show do
  use SmokexWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> SessionHelper.assign_user!(session)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  #
  # Private functions
  #

  defp max_plan_definitions,
    do: Application.get_env(:smokex, :limit_plan_definitions_per_organization)

  defp max_limit_executions_per_period,
    do: Application.get_env(:smokex, :limit_executions_per_period)

  defp max_limit_executions_expires_after_hours,
    do: Application.get_env(:smokex, :limit_executions_expires_after_hours)

  # TODO remove this crap after using gettext with plurals
  defp plural(:hour) do
    if Application.get_env(:smokex, :limit_executions_expires_after_hours) > 1 do
      "hours"
    else
      "hour"
    end
  end

  defp plural(:execution) do
    if Application.get_env(:smokex, :limit_executions_per_period) > 1 do
      "executions"
    else
      "execution"
    end
  end

  defp plural(:plan) do
    if Application.get_env(:smokex, :limit_plan_definitions_per_organization) > 1 do
      "workflows"
    else
      "workflow"
    end
  end
end
