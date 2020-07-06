defmodule SmokexWeb.PlansDefinitionsLive.List do
  use SmokexWeb, :live_view

  alias Smokex.PlanDefinitions

  @impl true
  def mount(_params, _session, socket) do
    all_plan_definitions = PlanDefinitions.all()

    {:ok, assign(socket, plan_definitions: all_plan_definitions)}
  end
end
