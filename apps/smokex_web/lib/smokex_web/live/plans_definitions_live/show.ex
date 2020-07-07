defmodule SmokexWeb.PlansDefinitionsLive.Show do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias Smokex.PlanDefinitions
  alias Smokex.PlanExecutions

  alias SmokexWeb.PlansExecutionsLive.Components.Table, as: TableComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _url, socket) do
    # if connected?(socket), do: Demo.Accounts.subscribe(plan_definition_id)
    socket =
      socket
      |> assign(id: id)
      |> fetch_plan_definition()
      |> fetch_plan_executions()

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
end
