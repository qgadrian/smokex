defmodule SmokexWeb.PlansExecutionsLive.List do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias Smokex.PlanDefinitions
  alias Smokex.PlanExecutions
  alias Smokex.PlanExecution
  alias SmokexWeb.PlansExecutionsLive.Components.Table, as: TableComponent
  alias SmokexWeb.PlansExecutionsLive.Components.Filter, as: FilterComponent

  @default_assigns [
    active_filter: :all
  ]

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, @default_assigns)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"plan_definition_id" => plan_definition_id}, _url, socket) do
    if connected?(socket), do: PlanDefinitions.subscribe(plan_definition_id)

    socket =
      socket
      |> assign(plan_definition_id: plan_definition_id)
      |> fetch_executions()

    {:noreply, socket}
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
        %{"filter" => filter_status},
        %Socket{assigns: %{plan_definition_id: plan_definition_id}} = socket
      ) do
    filter_status = String.to_existing_atom(filter_status)

    plan_executions = PlanExecutions.filtered_executions(plan_definition_id, filter_status)

    {:noreply, assign(socket, active_filter: filter_status, plan_executions: plan_executions)}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:created, %PlanExecution{status: status} = plan_execution},
        %Socket{assigns: %{plan_executions: plan_executions, active_filter: status}} = socket
      ) do
    plan_executions = [plan_execution | plan_executions]

    subscribe_to_changes(plan_execution)

    {:noreply, assign(socket, plan_executions: plan_executions)}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:created, %PlanExecution{}},
        %Socket{assigns: %{active_filter: :all}} = socket
      ) do
    socket = fetch_executions(socket)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:created, %PlanExecution{}}, %Socket{} = socket) do
    {:noreply, socket}
  end

  # TODO this won't add the plan execution to the active filter, only update if
  # it's already present.
  #
  # Since the first state is created, it will match in the `:created` event,
  # but if any other filter is active and then the execution changes to the
  # state in the filter we will need to check if it's present and add it
  # otherwise.
  #
  # Another solution could be fetch the executions.
  #
  @impl Phoenix.LiveView
  def handle_info(
        {_event, %PlanExecution{id: id} = plan_execution},
        %Socket{assigns: %{plan_executions: plan_executions}} = socket
      ) do
    plan_executions =
      Enum.map(plan_executions, fn
        %PlanExecution{id: ^id} -> plan_execution
        plan_execution -> plan_execution
      end)

    {:noreply, assign(socket, plan_executions: plan_executions)}
  end

  defp fetch_executions(%Socket{assigns: %{plan_definition_id: plan_definition_id}} = socket) do
    plan_executions =
      plan_definition_id
      |> PlanExecutions.filtered_executions(:all)
      |> subscribe_to_changes()

    assign(socket, plan_executions: plan_executions)
  end

  @spec subscribe_to_changes(PlanExecution.t() | list(PlanExecution.t())) ::
          list(PlanExecution.t())
  defp subscribe_to_changes(%PlanExecution{} = plan_execution) do
    subscribe_to_changes([plan_execution])
  end

  defp subscribe_to_changes(plan_executions) when is_list(plan_executions) do
    Enum.each(plan_executions, fn plan_execution ->
      Smokex.PlanExecutions.subscribe(plan_execution)
    end)

    plan_executions
  end
end
