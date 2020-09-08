defmodule SmokexWeb.SessionHelper do
  @moduledoc """
  Authentication helper functions for session credentials.

  For updates about Phoenix LiveView support see the following Github issue:
  https://github.com/danschultzer/pow/issues/271
  """

  require Logger

  alias Smokex.Users.User
  alias SmokexWeb.Tracer
  alias Phoenix.LiveView.Socket
  alias Pow.Store.CredentialsCache

  @doc """
  Gets the user from the session and assigns it to the Socket.

  This function assumes the session belongs to an authenticated user and raises
  an error if not.
  """
  @spec assign_user!(socket :: Socket.t(), session :: map, keyword) :: Socket.t()
  def assign_user!(%Socket{} = socket, session, opts \\ []) do
    with {:ok, user} <- get_user(socket, session, opts) do
      Phoenix.LiveView.assign(socket, current_user: user)
    else
      _ ->
        # TODO so raise an error or not?
        # raise "User not present in the socket session"
        Phoenix.LiveView.assign(socket, current_user: nil)
    end
  end

  @doc """
  Call the plug and update the user in the cached credentials.

  See: https://hexdocs.pm/pow/sync_user.html#update-user-in-the-credentials-cache
  """
  @spec sync_user(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def sync_user(conn, user), do: Pow.Plug.create(conn, user)

  @doc """
  Reloads all active session with the update user information from the
  database.

  This function receives a `t:Phoenix.LiveView.Socket.t/0` and a active session
  and returns the updated socket with the new `current_user` information.

  For more info see:
  * https://hexdocs.pm/pow/sync_user.html#reload-the-user
  * https://hexdocs.pm/pow/sync_user.html#update-user-in-the-credentials-cache
  * https://github.com/danschultzer/pow/issues/271#issuecomment-621979869
  """
  @spec reload_user(Phoenix.LiveView.Socket.t(), keyword()) :: :ok
  def reload_user(socket, %{"smokex_web_auth" => signed_token} = session, opts \\ []) do
    Logger.info("Reload user in credentials cache")

    conn = struct!(Plug.Conn, secret_key_base: socket.endpoint.config(:secret_key_base))

    pow_config = [otp_app: :smokex_web]
    salt = Atom.to_string(Pow.Plug.Session)

    with {:ok, token} <- Pow.Plug.verify_token(conn, salt, signed_token, pow_config),
         {user, metadata} <- CredentialsCache.get([backend: Pow.Store.Backend.EtsCache], token),
         {user, _metadata} = pow_credential <- {Smokex.Repo.get!(User, user.id), metadata},
         :ok <- update_sessions(pow_config, token, pow_credential),
         user <- maybe_preload_fields(user, opts[:preload]) do
      Phoenix.LiveView.assign(socket, current_user: user)
    else
      any ->
        socket
    end
  end

  #
  # Private functions
  #

  @spec maybe_preload_fields(User.t(), keyword | atom | nil) :: User.t()
  defp maybe_preload_fields(%User{} = user, nil), do: user
  defp maybe_preload_fields(%User{} = user, []), do: user

  defp maybe_preload_fields(%User{} = user, preload) do
    Smokex.Repo.preload(user, preload)
  end

  @spec update_sessions(
          pow_config :: keyword,
          session_token :: String.t(),
          {User.t(), metadata :: term}
        ) :: :ok
  defp update_sessions(pow_config, session_token, {%User{} = user, metadata} = pow_credential) do
    sessions = CredentialsCache.sessions(pow_config, user)

    # Do we have an available session which matches the fingerprint?
    sessions
    |> Enum.find(&(&1 == session_token))
    |> case do
      nil ->
        Logger.debug("No Matching Session Found")

      available_session ->
        Logger.debug("Matching session found, updating credential")
        CredentialsCache.put(pow_config, session_token, pow_credential)
    end
  end

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
         {user, _metadata} <- CredentialsCache.get([backend: Pow.Store.Backend.EtsCache], token),
         user <- maybe_preload_fields(user, config[:preload]) do
      Tracer.trace_user(user)

      {:ok, user}
    else
      _any -> nil
    end
  end

  def get_user(_, _, _) do
    Logger.warn("Cannot retrieve user from session, request not matched.")

    nil
  end
end
