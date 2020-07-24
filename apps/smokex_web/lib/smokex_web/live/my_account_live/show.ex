defmodule SmokexWeb.MyAccountLive.Show do
  use SmokexWeb, :live_view

  alias SmokexWeb.MyAccountLive.Components.SideMenu

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    socket =
      socket
      |> SessionHelper.assign_user!(session)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
