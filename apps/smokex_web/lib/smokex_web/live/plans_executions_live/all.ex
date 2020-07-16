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

    status =
      params
      |> Map.get("status", "all")
      |> String.to_existing_atom()

    plan_definition_id =
      params
      |> Map.get("plan", "")
      |> Integer.parse()
      |> case do
        {plan_definition_id, ""} -> plan_definition_id
        :error -> nil
      end

    socket =
      socket
      |> assign(page: page)
      |> assign(active_filter: status)
      |> assign(plan_definition_id: plan_definition_id)
      |> maybe_subscribe_to_plan_definition()
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
        :error -> nil
      end

    status_filter = String.to_existing_atom(status_filter)

    socket =
      socket
      |> assign(active_filter: status_filter)
      |> assign(plan_definition_id: plan_definition_id)
      |> fetch_executions

    path_to =
      case plan_definition_id do
        nil ->
          Routes.live_path(socket, SmokexWeb.PlansExecutionsLive.All, status_filter, 1)

        plan_definition_id ->
          Routes.live_path(socket, SmokexWeb.PlansExecutionsLive.All, status_filter, 1,
            plan: plan_definition_id
          )
      end

    {:noreply, push_patch(socket, to: path_to)}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:created, %PlanExecution{}},
        %Socket{assigns: %{active_filter: :all}} = socket
      ) do
    socket =
      socket
      |> fetch_executions()
      |> subscribe_to_changes()

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:created, %PlanExecution{status: status}},
        %Socket{assigns: %{active_filter: status}} = socket
      ) do
    socket =
      socket
      |> fetch_executions()
      |> subscribe_to_changes()

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(message, socket) do
    # TODO handle messages in this view
    Logger.debug(inspect(message))
    Logger.debug(inspect(socket))
    {:noreply, socket}
  end

  #
  # Private functions
  #

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

  @spec subscribe_to_changes(Socket.t()) :: list(PlanExecution.t())
  defp subscribe_to_changes(%Socket{assigns: %{plan_executions: plan_executions}} = socket)
       when is_list(plan_executions) do
    Smokex.PlanExecutions.subscribe(plan_executions)
    socket
  end

  @spec maybe_subscribe_to_plan_definition(Socket.t()) :: Socket.t()
  defp maybe_subscribe_to_plan_definition(
         %Socket{assigns: %{plan_definition_id: plan_definition_id}} = socket
       )
       when is_number(plan_definition_id) do
    PlanDefinitions.subscribe("#{plan_definition_id}")

    socket
  end

  defp maybe_subscribe_to_plan_definition(%Socket{} = socket), do: socket

  @spec page_path(Socket.t(), PlanExecution.status(), integer, integer | nil) :: term
  defp page_path(socket, active_filter, page, nil) do
    Routes.live_path(socket, SmokexWeb.PlansExecutionsLive.All, active_filter, page)
  end

  defp page_path(socket, active_filter, page, plan_definition_id) do
    Routes.live_path(socket, SmokexWeb.PlansExecutionsLive.All, active_filter, page,
      plan: plan_definition_id
    )
  end
end
