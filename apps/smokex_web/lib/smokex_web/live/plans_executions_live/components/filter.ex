defmodule SmokexWeb.PlansExecutionsLive.Components.Filter do
  use Phoenix.LiveComponent

  alias SmokexWeb.PlanExecutions.Components.FilterView

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{plan_executions: plan_executions}, socket) do
    {:ok, assign(socket, plan_executions: plan_executions)}
  end
end

