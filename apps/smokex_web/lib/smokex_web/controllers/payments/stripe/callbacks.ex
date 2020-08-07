defmodule SmokexWeb.Payments.Stripe.Callbacks do
  use SmokexWeb, :controller

  require Logger

  alias Smokex.Users.User
  alias Smokex.Repo

  plug :reload_user

  def success(conn, _params) do
    Logger.info("Callback received for success transaction")

    redirect(conn, to: "/plans")
  end

  def cancel(conn, _params) do
    Logger.info("Callback received for cancelled transaction")

    redirect(conn, to: "/plans")
  end

  @doc """
  Update the cached user credentials when an action outside of Pow has
  updated the user.

  The cached used needs to happen in the callback URLs since the user
  subscription will happen in a webhook where the process don't know which
  session the user has.

  For more info see:
  * https://hexdocs.pm/pow/sync_user.html#reload-the-user
  * https://hexdocs.pm/pow/sync_user.html#update-user-in-the-credentials-cache
  """
  @spec reload_user(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def reload_user(conn, _opts) do
    config = Pow.Plug.fetch_config(conn)
    user = Pow.Plug.current_user(conn, config)
    reloaded_user = Repo.get!(User, user.id)

    Logger.info("Callback received for user #{reloaded_user.id}")

    conn
    |> Pow.Plug.assign_current_user(reloaded_user, config)
    |> Pow.Plug.create(reloaded_user)
  end
end
