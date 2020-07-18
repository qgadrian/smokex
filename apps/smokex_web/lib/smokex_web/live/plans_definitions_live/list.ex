defmodule SmokexWeb.PlansDefinitionsLive.List do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias Smokex.PlanDefinitions
  alias SmokexWeb.PlanDefinitions.ListView
  alias SmokexWeb.SessionHelper

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(page_title: "Test plans")
      |> SessionHelper.assign_user!(session)
      |> fetch_plan_definitions()

    {:ok, socket}
  end

  @spec fetch_plan_definitions(Socket.t()) :: Socket.t()
  defp fetch_plan_definitions(%Socket{assigns: %{current_user: user}} = socket) do
    plan_definitions =
      user
      |> PlanDefinitions.all()
      |> Enum.map(&PlanDefinitions.preload_last_execution/1)

    assign(socket, plan_definitions: plan_definitions)
  end
end
