defmodule SmokexWeb.PlansExecutionsLive.Components.Table do
  use SmokexWeb, :live_component

  alias SmokexWeb.PlansExecutionsLive.Components.Row, as: RowComponent

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(%{plan_executions: plan_executions, id: id, update_action: update_action}, socket) do
    socket =
      socket
      |> assign(plan_executions: plan_executions)
      |> assign(id: id)
      |> assign(update_action: update_action)

    {:ok, socket}
  end
end
