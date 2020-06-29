defmodule Smokex.Repo do
  use Ecto.Repo,
    otp_app: :smokex,
    adapter: Ecto.Adapters.Postgres
end
