defmodule SmokexWeb.PlansExecutionsLive.Components.Show.Table do
  use Phoenix.LiveComponent

  alias Smokex.Result
  alias SmokexWeb.PlansExecutionsLive.Components.Show.Row

  def mount(socket) do
    {:ok, socket}
  end
end
