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
        %{"filter" => filter_name},
        %Socket{assigns: %{plan_definition_id: plan_definition_id}} = socket
      ) do
    plan_executions = PlanExecutions.get_by_plan_definition(plan_definition_id, filter_name)

    {:noreply, assign(socket, active_filter: filter_name, plan_executions: plan_executions)}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:created, %PlanExecution{} = plan_execution},
        %Socket{assigns: %{plan_executions: plan_executions}} = socket
      ) do
    plan_executions = [plan_execution | plan_executions]

    subscribe_to_changes(plan_execution)

    {:noreply, assign(socket, plan_executions: plan_executions)}
  end

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
      |> PlanExecutions.get_by_plan_definition()
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
