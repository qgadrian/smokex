defmodule SmokexWeb.MyAccountLive.Administration.Secrets.Show do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias SmokexWeb.MyAccountLive.Components.SideMenu
  alias Smokex.OrganizationsSecrets
  alias Smokex.Organizations.Secret
  alias Smokex.Organizations
  alias Smokex.Organizations.Organization

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    socket =
      socket
      |> SessionHelper.assign_user!(session)
      |> fetch_secrets()

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "delete",
        %{"id" => secret_id},
        %Socket{assigns: %{current_user: user}} = socket
      ) do
    with secret_id <- String.to_integer(secret_id),
         {:ok, %Organization{} = organization} <- Organizations.get_organization(user),
         %Secret{} = secret <- OrganizationsSecrets.get!(organization, secret_id),
         {:ok, _secret} <- OrganizationsSecrets.delete(secret) do
      socket = fetch_secrets(socket)

      {:noreply, socket}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        socket = put_flash(socket, :error, "Error deleting the secret, please contact support")

        {:noreply, socket}
    end
  end

  #
  # Private functions
  #

  defp fetch_secrets(%Socket{assigns: %{current_user: user}} = socket) do
    {:ok, %Organization{} = organization} = Organizations.get_organization(user)

    secrets = OrganizationsSecrets.list(organization)

    assign(socket, :secrets, secrets)
  end
end
