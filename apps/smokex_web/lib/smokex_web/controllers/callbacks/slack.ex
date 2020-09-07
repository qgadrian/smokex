defmodule SmokexWeb.Callbacks.Slack do
  @moduledoc """
  ```
  This module handles callbacks from Slack when an application is added to a
  workspace through Smokex.

  It is expected to wait the `user_id` be present on the `state` field.

  Example response from the Slack Oauth V2 access call:

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
  alias Smokex.Users.User
  alias Smokex.Repo
  alias Smokex.Integrations.Slack, as: SlackHelper

  # plug :reload_user

  # Slack verification https://api.slack.com/authentication/verifying-requests-from-slack
  @slack_version_number "v0"

  @client_id Application.compile_env(:slack, :client_id)
  @client_secret Application.compile_env(:slack, :client_secret)

  def callback(conn, %{"code" => code, "state" => user_id}) do
    Logger.info("Callback received for Slack authorization")

    conn
    |> validate_request!()
    |> get_access_token(code)
    |> add_user_token(user_id)

    redirect(conn, to: Routes.live_path(conn, SmokexWeb.MyAccountLive.Integrations.Slack))
  end

  #
  # Private functions
  #

  defp validate_request!(conn) do
    IO.inspect(conn)
    # [slack_timestamp] = Plug.Conn.get_req_header(conn, "X-Slack-Request-Timestamp")
    # [slack_signature] = Plug.Conn.get_req_header(conn, "X-Slack-Request-Timestamp")
  end

  defp get_access_token(_conn, code) do
    %{
      "access_token" => access_token,
      "app_id" => "A01AC9HHX7W",
      "ok" => true
    } = Slack.Web.Oauth.V2.access(@client_id, @client_secret, code)

    access_token
  end

  defp add_user_token(access_token, user_id) do
    SlackHelper.add_user_token(user_id, access_token)
  end
end
