defmodule SmokexWeb.MyAccountLive.Administration.Secrets.New do
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
      |> assign(changeset: Ecto.Changeset.change(%Secret{}))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "save",
        %{"secret" => secret_attrs},
        %Socket{assigns: %{current_user: user}} = socket
      ) do
    with {:ok, %Organization{} = organization} <- Organizations.get_organization(user),
         {:ok, %Secret{} = secret} <- OrganizationsSecrets.create(organization, secret_attrs) do
      redirect_path =
        Routes.live_path(socket, SmokexWeb.MyAccountLive.Administration.Secrets.Show)

      {:noreply, push_redirect(socket, to: redirect_path)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
