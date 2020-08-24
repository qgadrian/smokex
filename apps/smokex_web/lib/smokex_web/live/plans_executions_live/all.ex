defmodule SmokexWeb.PlansExecutionsLive.All do
  use SmokexWeb, :live_view

  require Logger

  alias Smokex.PlanExecutions.Subscriber, as: PlanExecutionsSubscriber
  alias Phoenix.LiveView.Socket
  alias Smokex.PlanDefinitions
  alias Smokex.PlanExecution
  alias Smokex.PlanExecutions
  alias SmokexWeb.PlansExecutionsLive.Components.Filter, as: FilterComponent
  alias SmokexWeb.PlansExecutionsLive.Components.Table, as: TableComponent

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(page_title: "Executions")
      |> SessionHelper.assign_user!(session)

    {:ok, socket}
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
      |> subscribe_to_changes()
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
  def handle_info(
        {_event, %PlanExecution{id: plan_execution_id} = plan_execution},
        %Socket{assigns: %{plan_executions: plan_executions}} = socket
      ) do
    updated_plan_executions =
      Enum.map(plan_executions, fn
        %PlanExecution{id: ^plan_execution_id} -> plan_execution
        other_plan_execution -> other_plan_execution
      end)

    socket = assign(socket, plan_executions: updated_plan_executions)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(message, socket) do
    Logger.warn("Received unhandled message #{inspect(message)}")

    {:noreply, socket}
  end

  #
  # Private functions
  #

  @spec fetch_executions(Socket.t()) :: Socket.t()
  defp fetch_executions(
         %Socket{
           assigns: %{
             current_user: user,
             active_filter: status,
             page: page,
             plan_definition_id: plan_definition_id
           }
         } = socket
       ) do
    plans_executions =
      user
      |> PlanExecutions.all(page, status: status, plan_definition_id: plan_definition_id)
      |> subscribe_to_changes()

    assign(socket, plan_executions: plans_executions)
  end

  @spec fetch_plan_definitions(Socket.t()) :: Socket.t()
  defp fetch_plan_definitions(%Socket{assigns: %{current_user: user}} = socket) do
    plan_definitions = PlanDefinitions.all(user)

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

  @spec subscribe_to_changes(Socket.t()) :: Socket.t()
  defp subscribe_to_changes(%Socket{assigns: %{plan_definition_id: plan_definition_id}} = socket)
       when is_number(plan_definition_id) do
    PlanDefinitions.subscribe("#{plan_definition_id}")

    socket
  end

  # TODO this will subscribe to all as a fallback. But this does not mean that
  # with an active filter, for example `finished` the process will be
  # subscribed (will not) and receive update messages
  defp subscribe_to_changes(%Socket{} = socket) do
    PlanExecutionsSubscriber.subscribe_to_any()

    socket
  end

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
