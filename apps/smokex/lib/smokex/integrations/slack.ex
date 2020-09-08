defmodule Smokex.Integrations.Slack do
  @moduledoc """
  Provides context to work with Slack integrations.
  """

  require Logger

  alias Smokex.Integrations.Slack.SlackIntegrationPreferences
  alias Smokex.Integrations.Slack.SlackUserIntegration
  alias Smokex.Repo
  alias Smokex.Users.User

  @doc """
  Adds a Slack token to a user.

  This function raises an error if the user already has a token configured.

  # TODO if the token is present delete and create a new entry instead of
  # failing
  """
  @spec add_user_token(user_id :: number, token :: String.t()) ::
          {:ok, SlackUserIntegration.t()} | {:error, Ecto.Changeset.t()}
  def add_user_token(user_id, token) do
    %SlackUserIntegration{}
    |> SlackUserIntegration.create_changeset(%{user_id: user_id, token: token})
    |> Repo.insert()
  end

  @doc """
  Deletes a user Slack the integration.

  This function also calls Slack to revoke the token.
  """
  @spec(remove_integration(User.t()) :: :ok, :error)
  def remove_integration(%User{} = user) do
    %User{
      slack_integration:
        %SlackUserIntegration{
          token: slack_integration_token
        } = slack_integration
    } = Smokex.Repo.preload(user, :slack_integration)

    with {:ok, _slack_integration} <- Smokex.Repo.delete(slack_integration),
         _ <- Slack.Web.Auth.revoke(%{token: slack_integration_token}) do
      :ok
    else
      error ->
        Logger.error(inspect(error))
        :error
    end
  end

  @doc """
  Post a Slack message.

  This function uses the configured token and channel of the user Slack integration.

  If the channel to post to is blank, returns an empty map.

  See `Slack.Web.Chat.post_message/3` for more info.
  """
  @spec post_message(SlackUserIntegration.t(), message :: String.t()) :: :ok
  def post_message(
        %SlackUserIntegration{options: %SlackIntegrationPreferences{post_to_channel: ""}},
        _message
      ) do
    Logger.debug("Skip post message to a empty channel")
    :ok
  end

  def post_message(
        %SlackUserIntegration{
          token: token,
          options: %SlackIntegrationPreferences{post_to_channel: channel}
        },
        message
      ) do
    channel
    |> Slack.Web.Chat.post_message(message, %{token: token})
    |> case do
      %{"ok" => true} -> :ok
      error -> Logger.warn(inspect(error))
    end
  end

  @doc """
  Updates a Slack integration preferences.
  """
  @spec update_preferences(User.t(), preferences_attrs :: map) ::
          {:ok, SlackUserIntegration.t()} | {:error, Ecto.Changeset.t()}
  def update_preferences(%User{} = user, preferences_attrs) when is_map(preferences_attrs) do
    %User{slack_integration: %SlackUserIntegration{} = slack_integration} =
      Smokex.Repo.preload(user, :slack_integration)

    slack_integration
    |> SlackUserIntegration.create_changeset(%{options: preferences_attrs})
    |> Smokex.Repo.update()
  end
end
