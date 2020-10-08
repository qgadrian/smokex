defmodule SmokexWeb.Controllers.Landing do
  use SmokexWeb, :controller

  def show(conn, _params) do
    render(conn, "show.html", changeset: Ecto.Changeset.change(%Smokex.Users.User{}))
  end
end
