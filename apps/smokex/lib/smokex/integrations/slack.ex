defmodule Smokex.Integrations.Slack do
  @moduledoc """
  Provides context to work with Slack integrations.
  """

  require Logger

  alias Smokex.Repo
  alias Smokex.Integrations.Slack.SlackUserIntegration
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
