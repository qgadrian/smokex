defmodule SmokexWeb.PlansExecutionsLive.Components.Row do
  use Phoenix.LiveComponent

  alias SmokexWeb.PlanExecutions.Components.RowView

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{id: id, plan_execution: plan_execution}, socket) do
    {:ok, assign(socket, id: id, plan_execution: plan_execution)}
  end
end
