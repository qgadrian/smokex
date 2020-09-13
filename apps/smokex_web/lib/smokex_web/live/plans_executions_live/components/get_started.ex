defmodule SmokexWeb.PlansExecutionsLive.Components.GetStarted do
  use SmokexWeb, :live_component

  use Phoenix.HTML

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end
end
