defmodule SmokexWeb.BlogLive.Show do
  use SmokexWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
