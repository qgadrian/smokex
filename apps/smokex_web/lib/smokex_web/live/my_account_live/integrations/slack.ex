defmodule SmokexWeb.MyAccountLive.Integrations.Slack do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias SmokexWeb.MyAccountLive.Components.SideMenu
  alias Smokex.Users.User
  alias Smokex.Integrations.Slack.SlackUserIntegration
  alias Smokex.Integrations.Slack.SlackIntegrationPreferences
  alias Smokex.Integrations.Slack

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    socket =
      socket
      |> SessionHelper.assign_user!(session, preload: :slack_integration)
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
    case Slack.update_preferences(current_user, preferences_attrs) do
      {:ok, %SlackUserIntegration{options: preferences}} ->
        changeset = Ecto.Changeset.change(preferences)
        {:noreply, assign(socket, changeset: changeset)}

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
    case Slack.remove_integration(current_user) do
      :ok ->
        socket = SessionHelper.reload_user(socket, session, preload: :slack_integration)

        {:noreply, socket}

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
               slack_integration: %SlackUserIntegration{
                 options: %SlackIntegrationPreferences{} = preferences
               }
             }
           }
         } = socket
       ) do
    changeset = Ecto.Changeset.change(preferences)
    assign(socket, changeset: changeset)
  end

  defp maybe_fetch_options(
         %Socket{assigns: %{current_user: %User{slack_integration: nil}}} = socket
       ) do
    socket
  end
end
