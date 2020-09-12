defmodule SmokexWeb.Callbacks.Slack do
  @moduledoc """
  This module handles callbacks from Slack when an application is added to a
  workspace through Smokex.

  It is expected to wait the `user_id` be present on the `state` field.

  Example response from the Slack Oauth V2 access call:

  ```
  %{
    "access_token" => access_token
    "app_id" => "XXXXXXXXXXX",
    "authed_user" => %{"id" => "XXXXXXXXX"},
    "bot_user_id" => "XXXXXXXXXXX",
    "enterprise" => nil,
    "ok" => true,
    "response_metadata" => %{"warnings" => ["superfluous_charset"]},
    "scope" => "channels:join,chat:write,chat:write.customize,commands,im:read,im:write,users:read,app_mentions:read",
    "team" => %{"id" => "XXXXXXXXX", "name" => "XXXXXXX"},
    "token_type" => "bot",
    "warning" => "superfluous_charset"
  }
  ```
  """
  use SmokexWeb, :controller

  require Logger

  alias SmokexWeb.Tracer
  alias Smokex.Users
  alias Smokex.Users.User
  alias Smokex.Organizations
  alias Smokex.Organizations.Organization
  alias Smokex.Repo
  alias Smokex.Integrations.Slack, as: SlackHelper

  # plug :reload_user

  # Slack verification https://api.slack.com/authentication/verifying-requests-from-slack
  @slack_version_number "v0"

  def callback(conn, %{"code" => code, "state" => user_id}) do
    Logger.info("Callback received for Slack authorization")

    conn
    |> validate_request!()
    |> get_access_token(code)
    |> insert_token_into_user_organization(user_id)

    redirect(conn, to: Routes.live_path(conn, SmokexWeb.MyAccountLive.Integrations.Slack))
  end

  #
  # Private functions
  #

  defp validate_request!(conn) do
    # [slack_timestamp] = Plug.Conn.get_req_header(conn, "X-Slack-Request-Timestamp")
    # [slack_signature] = Plug.Conn.get_req_header(conn, "X-Slack-Request-Timestamp")
    conn
  end

  defp get_access_token(_conn, code) do
    client_id = Application.get_env(:slack, :client_id)
    client_secret = Application.get_env(:slack, :client_secret)

    %{
      "access_token" => access_token,
      "app_id" => "A01AC9HHX7W",
      "ok" => true
    } = Slack.Web.Oauth.V2.access(client_id, client_secret, code)

    access_token
  end

  @spec insert_token_into_user_organization(String.t(), user_id :: integer) ::
          {:ok, term} | {:error, term}
  defp insert_token_into_user_organization(access_token, user_id) do
    with %User{} = user <- Users.get_by(id: user_id),
         {:ok, %Organization{id: organization_id}} <- Organizations.get_organization(user) do
      SlackHelper.insert_token(organization_id, access_token)
    else
      error ->
        Logger.error("Error inserting Slack token: #{inspect(error)}")
        {:error, "error inserting Slack token"}
    end
  end
end
