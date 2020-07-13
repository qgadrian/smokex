defmodule SmokexWeb.Controllers.Pricing do
  use SmokexWeb, :controller

  def show(conn, _params) do
    render(conn, "show.html")
  end
end
