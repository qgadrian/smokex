defmodule SmokexWeb.SessionHelper do
  @moduledoc """
  Authentication helper functions for session credentials.

  For updates about Phoenix LiveView support see the following Github issue:
  https://github.com/danschultzer/pow/issues/271
  """

  require Logger

  alias Smokex.Users.User
  alias Phoenix.LiveView.Socket
  alias Pow.Store.CredentialsCache

  @doc """
  Retrieves the currently-logged-in user from the Pow credentials cache.
  """
  @spec get_user(
          socket :: Socket.t(),
          session :: map(),
          config :: keyword()
        ) :: {:ok, %User{}} | nil
  def get_user(socket, session, config \\ [otp_app: :smokex_web])

  def get_user(%Socket{} = socket, %{"smokex_web_auth" => signed_token}, config) do
    conn = struct!(Plug.Conn, secret_key_base: socket.endpoint.config(:secret_key_base))
    salt = Atom.to_string(Pow.Plug.Session)

    with {:ok, token} <- Pow.Plug.verify_token(conn, salt, signed_token, config),
         {user, _metadata} <- CredentialsCache.get([backend: Pow.Store.Backend.EtsCache], token) do
      {:ok, user}
    else
      any -> nil
    end
  end

  def get_user(_, _, _) do
    Logger.warn("Cannot retrieve user from session, request not matched.")

    nil
  end

  @spec assign_user!(socket :: Socket.t(), session :: map) :: Socket.t()
  def assign_user!(%Socket{} = socket, session) do
    with {:ok, user} <- get_user(socket, session) do
      Phoenix.LiveView.assign(socket, current_user: user)
    else
      _ ->
        # raise "User not present in the socket session"
        Phoenix.LiveView.assign(socket, current_user: nil)
    end
  end

  @doc """
  Call the plug and update the cached credentials.

  See: https://hexdocs.pm/pow/sync_user.html#update-user-in-the-credentials-cache
  """
  @spec sync_user(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def sync_user(conn, user), do: Pow.Plug.create(conn, user)
end