defmodule SmokexWeb.PlansExecutionsLive.All do
  use SmokexWeb, :live_view

  require Logger

  alias Phoenix.LiveView.Socket
  alias Smokex.PlanExecutions
  alias Smokex.PlanDefinitions
  alias Smokex.PlanExecution
  alias SmokexWeb.PlansExecutionsLive.Components.Table, as: TableComponent
  alias SmokexWeb.PlansExecutionsLive.Components.Filter, as: FilterComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Executions")}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {page, ""} = Integer.parse(params["page"] || "1")
    status = Map.get(params, "status", "all")

    plan_definition_id =
      params
      |> Map.get("plan", "")
      |> Integer.parse()
      |> case do
        {plan_definition_id, ""} -> plan_definition_id
        :error -> ""
      end

    socket =
      socket
      |> assign(page: page)
      |> assign(active_filter: status)
      |> assign(plan_definition_id: plan_definition_id)
      |> fetch_executions
      |> fetch_plan_definitions

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "filter_update",
        %{"filter" => %{"plan_definition_id" => plan_definition_id, "status" => status_filter}},
        %Socket{} = socket
      ) do
    plan_definition_id =
      case Integer.parse(plan_definition_id) do
        {plan_definition_id, ""} -> plan_definition_id
        :error -> ""
      end

    socket =
      socket
      |> assign(active_filter: status_filter)
      |> assign(plan_definition_id: plan_definition_id)
      |> fetch_executions

    path_to =
      case plan_definition_id do
        "" ->
          Routes.live_path(socket, SmokexWeb.PlansExecutionsLive.All, status_filter, 1)

        plan_definition_id ->
          Routes.live_path(socket, SmokexWeb.PlansExecutionsLive.All, status_filter, 1,
            plan: plan_definition_id
          )
      end

    {:noreply,
     socket
     |> push_patch(to: path_to)}

    # {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(message, socket) do
    # TODO handle messages in this view
    Logger.error(inspect(message))
    {:noreply, socket}
  end

  @spec fetch_executions(Socket.t()) :: Socket.t()
  defp fetch_executions(
         %Socket{
           assigns: %{active_filter: status, page: page, plan_definition_id: plan_definition_id}
         } = socket
       ) do
    # TODO make this configurable
    plans_executions =
      status
      |> PlanExecutions.by_status(page, 20, plan_definition_id: plan_definition_id)
      |> subscribe_to_changes()

    assign(socket, plan_executions: plans_executions)
  end

  @spec fetch_plan_definitions(Socket.t()) :: Socket.t()
  defp fetch_plan_definitions(%Socket{} = socket) do
    plan_definitions = PlanDefinitions.all()

    assign(socket, plan_definitions: plan_definitions)
  end

  @spec subscribe_to_changes(list(PlanExecution.t())) :: list(PlanExecution.t())
  defp subscribe_to_changes(plan_executions) when is_list(plan_executions) do
    Smokex.PlanExecutions.subscribe(plan_executions)
    plan_executions
  end
end
