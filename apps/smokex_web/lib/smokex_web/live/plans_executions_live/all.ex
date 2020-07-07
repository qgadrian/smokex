defmodule SmokexWeb.PlansExecutionsLive.All do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias Smokex.PlanExecutions
  alias Smokex.PlanExecution
  alias SmokexWeb.PlansExecutionsLive.Components.Table, as: TableComponent
  alias SmokexWeb.PlansExecutionsLive.Components.Filter, as: FilterComponent

  @default_assigns [
    active_filter: :all
  ]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(@default_assigns)
      |> fetch_executions

    {:ok, socket}
  end

  def handle_event("filter_executions", %{"filter" => "all"}, %Socket{} = socket) do
    socket =
      socket
      |> assign(active_filter: :all)
      |> fetch_executions

    {:noreply, socket}
  end

  def handle_event(
        "filter_executions",
        %{"filter" => filter_name},
        %Socket{} = socket
      ) do
    plan_executions = PlanExecutions.by_status(filter_name)

    {:noreply, assign(socket, active_filter: filter_name, plan_executions: plan_executions)}
  end

  defp fetch_executions(%Socket{} = socket) do
    plans_executions = PlanExecutions.all()
    assign(socket, plan_executions: plans_executions)
  end
end
