defmodule SmokexWeb.StatusLive.Show do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias Smokex.PlanExecutions
  alias SmokexWeb.PlansExecutionsLive.Components.Table, as: TableComponent

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> fetch_plan_executions()
      |> fetch_total_executions()
      |> fetch_executions_summary()

    {:ok, socket}
  end

  defp fetch_plan_executions(%Socket{} = socket) do
    plan_executions = PlanExecutions.last_executions(10)
    assign(socket, plan_executions: plan_executions)
  end

  defp fetch_executions_summary(%Socket{} = socket) do
    executions_summary = PlanExecutions.executions_summary()
    assign(socket, executions_summary: executions_summary)
  end

  defp fetch_total_executions(%Socket{} = socket) do
    total_executions = PlanExecutions.total_executions()
    assign(socket, total_executions: total_executions)
  end
end
