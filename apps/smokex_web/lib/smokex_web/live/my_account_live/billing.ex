defmodule SmokexWeb.MyAccountLive.Billing do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias SmokexWeb.MyAccountLive.Components.SideMenu
  alias Smokex.StripeSubscriptions

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

  @impl Phoenix.LiveView
  def handle_event("show_cancel_subscription_modal", _params, socket) do
    {:noreply, show_modal(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("hide_cancel_subscription_modal", _params, socket) do
    {:noreply, hide_modal(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "cancel_subscription",
        _params,
        %Socket{assigns: %{current_user: user}} = socket
      ) do
    with {:ok, :delete} <- StripeSubscriptions.cancel_subscription(user) do
      {:noreply, hide_modal(socket)}
    else
      _error ->
        put_flash(
          socket,
          :error,
          "Error managing subscription, please email us at contact@smokex.io"
        )

        {:noreply, hide_modal(socket)}
    end
  end

  #
  # Private functions
  #
  @spec show_modal(Socket.t()) :: Socket.t()
  defp show_modal(%Socket{} = socket), do: assign(socket, show_confirm_modal: true)
  defp hide_modal(%Socket{} = socket), do: assign(socket, show_confirm_modal: false)
end
