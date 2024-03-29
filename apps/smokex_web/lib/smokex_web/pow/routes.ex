defmodule SmokexWeb.Pow.Routes do
  use Pow.Phoenix.Routes
  alias SmokexWeb.Router.Helpers, as: Routes

  @impl Pow.Phoenix.Routes
  def after_user_updated_path(conn) do
    Routes.live_path(conn, SmokexWeb.MyAccountLive.Show)
  end

  @impl Pow.Phoenix.Routes
  def after_registration_path(conn) do
    Routes.live_path(conn, SmokexWeb.WelcomeLive.Show)
  end

  @impl Pow.Phoenix.Routes
  def after_sign_in_path(conn), do: Routes.live_path(conn, SmokexWeb.PlansExecutionsLive.List)
end
