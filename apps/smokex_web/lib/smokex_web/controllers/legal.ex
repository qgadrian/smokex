defmodule SmokexWeb.Controllers.Legal do
  use SmokexWeb, :controller

  def privacy_policy(conn, _params) do
    render(conn, "privacy_policy.html")
  end

  def terms_and_conditions(conn, _params) do
    render(conn, "terms_and_conditions.html")
  end
end
