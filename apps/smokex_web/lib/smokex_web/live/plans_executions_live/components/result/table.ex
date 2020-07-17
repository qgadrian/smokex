defmodule SmokexWeb.PlansExecutionsLive.Components.Result.Table do
  use Phoenix.LiveComponent

  alias Smokex.Result
  alias SmokexWeb.PlansExecutionsLive.Components.Result.Row

  def mount(socket) do
    {:ok, socket}
  end
end
