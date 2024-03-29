defmodule SmokexWeb.PlansExecutionsLive.Components.Sidebar do
  use SmokexWeb, :live_component

  use Phoenix.HTML

  def mount(socket) do
    {:ok, socket}
  end

  def update(
        %{
          plan_executions: plan_executions,
          active_filter: active_filter,
          plan_definition_id: plan_definition_id,
          plan_definitions: plan_definitions,
          current_user: current_user
        },
        socket
      ) do
    {:ok,
     assign(socket,
       plan_executions: plan_executions,
       active_filter: active_filter,
       plan_definition_id: plan_definition_id,
       plan_definitions: plan_definitions,
       current_user: current_user
     )}
  end
end
