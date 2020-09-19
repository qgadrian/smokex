defmodule SmokexWeb.MyAccountLive.Administration.Secrets.Edit do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias SmokexWeb.MyAccountLive.Components.SideMenu
  alias Smokex.OrganizationsSecrets
  alias Smokex.Organizations
  alias Smokex.Organizations.Organization
  alias Smokex.Organizations.Secret

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    socket =
      socket
      |> SessionHelper.assign_user!(session)
    # TODO kick user out if they dont belong to the orgnaization secret
      |> fetch_secret()

    {:ok, socket, temporary_assigns: [changeset: Ecto.Changeset.change(%Secret{})]}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    {:noreply, assign(socket, :id, String.to_integer(id))}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"secret" => secret_attrs}, %Socket{assigns: %{id: secret_id, current_user: user}} = socket) do
    with %Secret{} = secret <- OrganizationsSecrets.get(secret_id),
         {:ok, %Secret{} = secret} <- OrganizationsSecrets.update(secret, secret_attrs) do
        redirect_path =
          Routes.live_path(socket, SmokexWeb.MyAccountLive.Administration.Secrets.Show)

        {:noreply, push_redirect(socket, to: redirect_path)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  #
  # Private functions
  #

  defp fetch_secret(%Socket{assigns: %{id: secret_id}} = socket) do
    changeset = OrganizationsSecrets.get(secret_id)

    socket
    |> assign(changeset: changeset)
  end

  defp fetch_secret(socket), do: socket
end

