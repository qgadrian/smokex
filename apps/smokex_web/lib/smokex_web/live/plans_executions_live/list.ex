defmodule SmokexWeb.PlansExecutionsLive.List do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias Smokex.PlanExecutions
  alias SmokexWeb.PlansExecutionsLive.Components.Row, as: RowComponent
  alias SmokexWeb.PlansExecutionsLive.Components.Filter, as: FilterComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"plan_definition_id" => plan_definition_id}, _url, socket) do
    # if connected?(socket), do: Demo.Accounts.subscribe(plan_definition_id)
    socket =
      socket
      |> assign(plan_definition_id: plan_definition_id)
      |> fetch_executions()

    {:noreply, socket}
  end

  defp fetch_executions(%Socket{assigns: %{plan_definition_id: plan_definition_id}} = socket) do
    plan_definition_executions = PlanExecutions.list_by_plan_definition(plan_definition_id)
    assign(socket, plan_executions: plan_definition_executions)
  end
end
