defmodule Smokex.Integrations.Slack do
  @moduledoc """
  Provides context to work with Slack integrations.
  """

  require Logger

  alias Smokex.Integrations.Slack.SlackIntegrationPreferences
  alias Smokex.Integrations.Slack.SlackIntegration
  alias Smokex.Repo
  alias Smokex.Organizations.Organization

  @doc """
  Adds a Slack token to a user.

  This function raises an error if the user already has a token configured.

  # TODO if the token is present delete it and create a new entry instead of
  # failing
  """
  @spec insert_token(organization_id :: number, token :: String.t()) ::
          {:ok, SlackIntegration.t()} | {:error, Ecto.Changeset.t()}
  def insert_token(organization_id, token) do
    %SlackIntegration{}
    |> SlackIntegration.create_changeset(%{organization_id: organization_id, token: token})
    |> Repo.insert()
  end

  @doc """
  Deletes a organization Slack the integration.

  This function also calls Slack to revoke the token. Notice this actions is
  not transaction and deleting an integration does not assure the token has
  being revoked from the Slack servers.
  """
  @spec(remove_integration(Organization.t()) :: :ok, :error)
  def remove_integration(%Organization{} = organization) do
    with {:ok, %SlackIntegration{token: slack_integration_token} = slack_integration} <-
           get_integration(organization),
         {:ok, _slack_integration} <- Smokex.Repo.delete(slack_integration),
         _ <- Slack.Web.Auth.revoke(%{token: slack_integration_token}) do
      :ok
    else
      error ->
        Logger.error(inspect(error))
        :error
    end
  end

  @doc """
  Returns the Slack integration for an organization.

  If there is no Slack integration configured for the organization, an error is
  returned.
  """
  @spec get_integration(Organization.t()) :: {:ok, SlackIntegration.t()} | {:error, term}
  def get_integration(%Organization{} = organization) do
    organization
    |> Smokex.Repo.preload(:slack_integration)
    |> case do
      %Organization{slack_integration: %SlackIntegration{} = slack_integration} ->
        {:ok, slack_integration}

      %Organization{slack_integration: nil} ->
        {:error, "no Slack integration configured"}
    end
  end

  @doc """
  Post a Slack message.

  This function uses the configured token and channel of the user Slack integration.

  If the channel to post to is blank, returns an empty map.

  See `Slack.Web.Chat.post_message/3` for more info.
  """
  def post_message(_slack_user_integration, _message, _opts \\ %{})

  @spec post_message(SlackIntegration.t(), message :: String.t()) :: :ok
  def post_message(
        %SlackIntegration{options: %SlackIntegrationPreferences{post_to_channel: ""}},
        _message,
        _opts
      ) do
    Logger.debug("Skip post message to a empty channel")
    :ok
  end

  def post_message(
        %SlackIntegration{
          token: token,
          options: %SlackIntegrationPreferences{post_to_channel: channel}
        },
        message,
        opts
      ) do
    opts = Map.merge(opts, %{token: token})

    Logger.debug("Slack post to #{channel}: #{message} // #{inspect(opts)}")

    channel
    |> Slack.Web.Chat.post_message(message, opts)
    |> case do
      %{"ok" => true} -> :ok
      error -> Logger.warn(inspect(error))
    end
  end

  @doc """
  Updates a Slack integration preferences.
  """
  @spec update_preferences(Organization.t(), preferences_attrs :: map) ::
          {:ok, SlackIntegration.t()} | {:error, Ecto.Changeset.t()}
  def update_preferences(%Organization{} = organization, preferences_attrs)
      when is_map(preferences_attrs) do
    {:ok, %SlackIntegration{} = slack_integration} = get_integration(organization)

    slack_integration
    |> SlackIntegration.create_changeset(%{options: preferences_attrs})
    |> Smokex.Repo.update()
  end
end
