defmodule SmokexWeb.PlansExecutionsLive.ListTest do
  use SmokexWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.LiveViewTest

  import Smokex.TestSupport.Factories

  alias Smokex.Users.User

  describe "when the user has created a plan definition" do
    setup %{conn: conn} do
      organization = insert(:organization)
      user = insert(:user, organizations: [organization])
      _plan_definition = insert(:plan_definition, author: user, organization: organization)

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Pow.Plug.Session.call(otp_app: :smokex_web)
        |> SmokexWeb.SessionHelper.sync_user(user)

      {:ok, conn: conn}
    end

    test "renders the executions", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/executions")

      assert html =~ "<ul id=\"executions-list\" phx-update=\"append\">"
      refute html =~ "<h2 class=\"title\">Get started with Smokex Plans</h2>"
    end
  end

  describe "when the user did not create a plan definition" do
    test "renders a getting started view", %{conn: conn} do
      user = %User{email: "test@example.com"}
      conn = Pow.Plug.assign_current_user(conn, user, otp_app: :smokex_web)

      {:ok, _view, html} = live(conn, "/executions")
      assert html =~ "<h2 class=\"title\">Get started with Smokex Plans</h2>"
    end
  end
end
