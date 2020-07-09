defmodule SmokexWeb.PlansExecutionsLive.All do
  use SmokexWeb, :live_view

  require Logger

  alias Phoenix.LiveView.Socket
  alias Smokex.PlanExecutions
  alias Smokex.PlanExecution
  alias SmokexWeb.PlansExecutionsLive.Components.Table, as: TableComponent
  alias SmokexWeb.PlansExecutionsLive.Components.Filter, as: FilterComponent

  @default_assigns [
    active_filter: :all
  ]

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(@default_assigns)
      |> fetch_executions

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("filter_executions", %{"filter" => "all"}, %Socket{} = socket) do
    socket =
      socket
      |> assign(active_filter: :all)
      |> fetch_executions

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "filter_executions",
        %{"filter" => filter_name},
        %Socket{} = socket
      ) do
    plan_executions = PlanExecutions.by_status(filter_name)

    {:noreply, assign(socket, active_filter: filter_name, plan_executions: plan_executions)}
  end

  @impl Phoenix.LiveView
  def handle_info(message, socket) do
    # TODO handle messages in this view
    Logger.error(inspect(message))
    {:noreply, socket}
  end

  defp fetch_executions(%Socket{} = socket) do
    plans_executions =
      PlanExecutions.all()
      |> subscribe_to_changes()

    assign(socket, plan_executions: plans_executions)
  end

  @spec subscribe_to_changes(list(PlanExecution.t())) :: list(PlanExecution.t())
  defp subscribe_to_changes(plan_executions) when is_list(plan_executions) do
    Smokex.PlanExecutions.subscribe(plan_executions)
    plan_executions
  end
end
