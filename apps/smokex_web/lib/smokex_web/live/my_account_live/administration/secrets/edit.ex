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

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"name" => secret_name}, _url, socket) do
    socket =
      socket
      |> assign(:name, secret_name)
      |> fetch_secret()

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "save",
        %{"secret" => secret_attrs},
        %Socket{assigns: %{name: secret_name, current_user: user}} = socket
      ) do
    with {:ok, %Organization{} = organization} <- Organizations.get_organization(user),
         %Secret{} = secret <- OrganizationsSecrets.get!(organization, secret_name),
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

  defp fetch_secret(%Socket{assigns: %{current_user: user, name: secret_name}} = socket) do
    with {:ok, %Organization{} = organization} <- Organizations.get_organization(user),
         %Secret{} = secret <- OrganizationsSecrets.get!(organization, secret_name),
         changeset <- Ecto.Changeset.change(secret) do
      assign(socket, changeset: changeset)
    else
      _ ->
        redirect_path =
          Routes.live_path(socket, SmokexWeb.MyAccountLive.Administration.Secrets.Show)

        {:noreply, push_redirect(socket, to: redirect_path)}
    end
  end

  defp fetch_secret(socket) do
    redirect_path = Routes.live_path(socket, SmokexWeb.MyAccountLive.Administration.Secrets.Show)

    {:noreply, push_redirect(socket, to: redirect_path)}
  end
end
