defmodule SmokexWeb.PlansExecutionsLive.All do
  use SmokexWeb, :live_view

  require Logger

  alias Phoenix.LiveView.Socket
  alias Smokex.PlanExecutions
  alias Smokex.PlanExecution
  alias SmokexWeb.PlansExecutionsLive.Components.Table, as: TableComponent
  alias SmokexWeb.PlansExecutionsLive.Components.Filter, as: FilterComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {page, ""} = Integer.parse(params["page"] || "1")
    status = Map.get(params, "status", "all")

    socket =
      socket
      |> assign(page: page)
      |> assign(active_filter: status)
      |> fetch_executions

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "filter_executions",
        %{"filter" => filter_name},
        %Socket{} = socket
      ) do
    socket =
      socket
      |> assign(active_filter: filter_name)
      |> fetch_executions

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(message, socket) do
    # TODO handle messages in this view
    Logger.error(inspect(message))
    {:noreply, socket}
  end

  defp fetch_executions(%Socket{assigns: %{active_filter: status, page: page}} = socket) do
    # TODO make this configurable
    plans_executions =
      status
      |> PlanExecutions.by_status(page, 20)
      |> subscribe_to_changes()

    assign(socket, plan_executions: plans_executions)
  end

  @spec subscribe_to_changes(list(PlanExecution.t())) :: list(PlanExecution.t())
  defp subscribe_to_changes(plan_executions) when is_list(plan_executions) do
    Smokex.PlanExecutions.subscribe(plan_executions)
    plan_executions
  end
end
