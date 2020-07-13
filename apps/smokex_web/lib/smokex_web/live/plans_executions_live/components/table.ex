defmodule SmokexWeb.PlansExecutionsLive.Components.Table do
  use Phoenix.LiveComponent

  alias SmokexWeb.PlansExecutionsLive.Components.Row, as: RowComponent

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{plan_executions: plan_executions}, socket) do
    socket =
      socket
      |> assign(plan_executions: plan_executions)

    {:ok, socket}
  end
end

