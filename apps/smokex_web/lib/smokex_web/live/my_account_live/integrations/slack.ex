defmodule SmokexWeb.MyAccountLive.Integrations.Slack do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias SmokexWeb.MyAccountLive.Components.SideMenu
  alias Smokex.Users.User
  alias Smokex.Organizations
  alias Smokex.Organizations.Organization
  alias Smokex.Integrations.Slack.SlackIntegration
  alias Smokex.Integrations.Slack.SlackIntegrationPreferences
  alias Smokex.Integrations.Slack

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    socket =
      socket
      |> SessionHelper.assign_user!(session, preload: :organizations)
      |> assign(:session, session)
      |> maybe_fetch_options()

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "save",
        %{"slack_integration_preferences" => preferences_attrs},
        %Socket{assigns: %{current_user: current_user}} = socket
      ) do
    with {:ok, %Organization{} = organization} <- Organizations.get_organization(current_user),
         {:ok, %SlackIntegration{options: preferences}} <-
           Slack.update_preferences(organization, preferences_attrs) do
      changeset = Ecto.Changeset.change(preferences)
      {:noreply, assign(socket, changeset: changeset)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event(
        "remove_integration",
        _params,
        %Socket{assigns: %{current_user: current_user, session: session}} = socket
      ) do
    with {:ok, %Organization{} = organization} <- Organizations.get_organization(current_user),
         :ok <- Slack.remove_integration(current_user) do
      socket = SessionHelper.reload_user(socket, session, preload: :slack_integration)

      {:noreply, socket}
    else
      :error ->
        socket =
          put_flash(
            socket,
            :error,
            "Error removing the Slack integration, please contact support@smokex.io"
          )

        {:noreply, socket}
    end
  end

  #
  # Private functions
  #

  defp maybe_fetch_options(
         %Socket{
           assigns: %{
             current_user: %User{
               organizations: [%Organization{} = organization]
             }
           }
         } = socket
       ) do
    with {:ok, %SlackIntegration{options: preferences}} <- Slack.get_integration(organization) do
      changeset = Ecto.Changeset.change(preferences)
      assign(socket, changeset: changeset)
    else
      _ -> socket
    end
  end

  @spec user_organization_has_slack_integration?(User.t()) :: boolean
  defp user_organization_has_slack_integration?(%User{} = user) do
    with {:ok, %Organization{} = organization} <- Organizations.get_organization(user),
         {:ok, %SlackIntegration{}} <- Slack.get_integration(organization) do
      true
    else
      _ -> false
    end
  end
end
