defmodule SmokexWeb.PlansDefinitionsLive.Show do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias Smokex.PlanDefinitions
  alias Smokex.PlanExecutions
  alias Smokex.PlanExecution

  alias SmokexWeb.PlansExecutionsLive.Components.Table, as: TableComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    if connected?(socket), do: PlanDefinitions.subscribe(id)

    socket =
      socket
      |> assign(id: id)
      |> fetch_plan_definition()
      |> fetch_plan_executions()

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "execute",
        _params,
        %Socket{assigns: %{plan_definition: plan_definition}} = socket
      ) do
    {:ok, plan_execution} = PlanExecutions.create_plan_execution(plan_definition)
    Smokex.PlanExecutions.subscribe(plan_execution)

    PlanExecutions.start(plan_execution)

    {:noreply, socket}
  end

  defp fetch_plan_definition(%Socket{assigns: %{id: id}} = socket) do
    plan_definition = PlanDefinitions.get(id)
    assign(socket, plan_definition: plan_definition)
  end

  defp fetch_plan_executions(%Socket{assigns: %{id: id}} = socket) do
    plan_executions = PlanExecutions.get_by_plan_definition(id, 5)
    assign(socket, plan_executions: plan_executions)
  end

  # TODO move to a show view
  @impl Phoenix.LiveView
  def handle_info(
        {:created, %PlanExecution{} = plan_execution},
        %Socket{assigns: %{plan_executions: plan_executions}} = socket
      ) do
    plan_executions = Enum.take([plan_execution | plan_executions], 5)
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
end
