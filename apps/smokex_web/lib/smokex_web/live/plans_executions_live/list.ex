defmodule SmokexWeb.PlansExecutionsLive.List do
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
    {:ok, assign(socket, @default_assigns)}
  end

  def handle_params(%{"plan_definition_id" => plan_definition_id}, _url, socket) do
    # if connected?(socket), do: Demo.Accounts.subscribe(plan_definition_id)
    socket =
      socket
      |> assign(plan_definition_id: plan_definition_id)
      |> fetch_executions()

    {:noreply, socket}
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
        %Socket{assigns: %{plan_definition_id: plan_definition_id}} = socket
      ) do
    plan_executions = PlanExecutions.get_by_plan_definition(plan_definition_id, filter_name)

    {:noreply, assign(socket, active_filter: filter_name, plan_executions: plan_executions)}
  end

  defp fetch_executions(%Socket{assigns: %{plan_definition_id: plan_definition_id}} = socket) do
    plan_definition_executions = PlanExecutions.get_by_plan_definition(plan_definition_id)
    assign(socket, plan_executions: plan_definition_executions)
  end
end
