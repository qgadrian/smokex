defmodule SmokexWeb.PlansExecutionsLive.Components.Row do
  use SmokexWeb, :live_component

  alias SmokexWeb.PlanExecutions.Components.StatusBadge

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{id: id, plan_execution: plan_execution}, socket) do
    {:ok, assign(socket, id: id, plan_execution: plan_execution)}
  end
end
