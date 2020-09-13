defmodule SmokexWeb.StatsLive.Show do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias Smokex.PlanExecutions
  alias SmokexWeb.PlansExecutionsLive.Components.Table, as: TableComponent
  alias SmokexWeb.SessionHelper

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(page_title: "Stats")
      |> SessionHelper.assign_user!(session)
      |> fetch_plan_executions()
      |> fetch_total_executions()
      |> fetch_executions_summary()

    {:ok, socket}
  end

  #
  # Private functions
  #
  defp fetch_plan_executions(%Socket{assigns: %{current_user: user}} = socket) do
    plan_executions =
      PlanExecutions.last_executions(user, limit: 10)
      |> Smokex.Repo.preload(:plan_definition)
    assign(socket, plan_executions: plan_executions)
  end

  defp fetch_executions_summary(%Socket{assigns: %{current_user: user}} = socket) do
    executions_summary = PlanExecutions.executions_summary(user)
    assign(socket, executions_summary: executions_summary)
  end

  defp fetch_total_executions(%Socket{assigns: %{current_user: user}} = socket) do
    total_executions = PlanExecutions.total_executions(user)
    assign(socket, total_executions: total_executions)
  end
end
