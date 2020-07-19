defmodule SmokexWeb.PricingLive.Show do
  use SmokexWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> SessionHelper.assign_user!(session)

    {:ok, socket}
  end
end
