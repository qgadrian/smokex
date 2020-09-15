defmodule SmokexWeb.PlansExecutionsLive.Components.Table do
  use SmokexWeb, :live_component

  alias SmokexWeb.PlansExecutionsLive.Components.Row, as: RowComponent

  @impl Phoenix.LiveView
  def mount(socket) do
    {:ok, socket}
  end

  def update(%{plan_executions: plan_executions, id: id}, socket) do
    socket =
      socket
      |> assign(plan_executions: plan_executions)
      |> assign(id: id)

    {:ok, socket}
  end
end
