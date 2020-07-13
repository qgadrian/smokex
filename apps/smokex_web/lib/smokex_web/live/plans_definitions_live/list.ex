defmodule SmokexWeb.PlansDefinitionsLive.List do
  use SmokexWeb, :live_view

  alias SmokexWeb.PlanDefinitions.ListView
  alias Phoenix.LiveView.Socket
  alias Smokex.PlanDefinitions
  alias Smokex.PlanDefinition

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> fetch_plan_definitions()

    {:ok, socket}
  end

  @spec fetch_plan_definitions(Socket.t()) :: list(PlanDefinition.t())
  defp fetch_plan_definitions(%Socket{} = socket) do
    plan_definitions =
      PlanDefinitions.all()
      |> Enum.map(&PlanDefinitions.preload_last_execution/1)

    assign(socket, plan_definitions: plan_definitions)
  end
end
