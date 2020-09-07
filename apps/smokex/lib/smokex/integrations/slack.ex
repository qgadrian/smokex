defmodule Smokex.Integrations.Slack do
  @moduledoc """
  Provides context to work with Slack integrations.
  """

  alias Smokex.Repo
  alias Smokex.Integrations.Slack.SlackUserIntegration
  alias Smokex.Users.User

  @doc """
  Adds a Slack token to a user.

  This function raises an error if the user already has a token configured.

  # TODO if the token is present delete and create a new entry
  """
  @spec add_user_token(user_id :: number, token :: String.t()) ::
          {:ok, SlackUserIntegration.t()} | {:error, Ecto.Changeset.t()}
  def add_user_token(user_id, token) do
    %SlackUserIntegration{}
    |> SlackUserIntegration.create_changeset(%{user_id: user_id, token: token})
    |> Repo.insert()
  end

  @doc """
  Post a Slack message.

  This function uses the configured token for the user Slack integration.

  See `Slack.Web.Chat.post_message/3` for more info.
  """
  @spec post_message(User.t(), channel :: String.t(), message :: String.t()) :: map
  def post_message(%User{} = user, channel, message) do
    %User{slack_integration: slack_integration} = Smokex.Repo.preload(user, :slack_integration)

    Slack.Web.Chat.post_message("smokex_test", message, %{token: slack_integration.token})
  end

  @doc """
  Updates a Slack integration.
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
