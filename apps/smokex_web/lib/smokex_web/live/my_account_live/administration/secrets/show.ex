defmodule SmokexWeb.MyAccountLive.Administration.Secrets.Show do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias SmokexWeb.MyAccountLive.Components.SideMenu
  alias Smokex.OrganizationsSecrets
  alias Smokex.Organizations
  alias Smokex.Organizations.Organization

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    socket =
      socket
      |> SessionHelper.assign_user!(session)
      |> assign_secrets()

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  #
  # Private functions
  #

  defp assign_secrets(%Socket{assigns: %{current_user: user}} = socket) do
    {:ok, %Organization{} = organization} = Organizations.get_organization(user)

    secrets = OrganizationsSecrets.list(organization)

    assign(socket, :secrets, secrets)
  end
end
