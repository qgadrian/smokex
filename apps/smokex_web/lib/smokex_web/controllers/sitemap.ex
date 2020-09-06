defmodule SmokexWeb.Controllers.Sitemap do
  use SmokexWeb, :controller

  plug :put_root_layout, false

  def build(conn, _params) do
    conn
    |> put_resp_content_type("text/xml")
    |> render("show.xml")
  end
end
