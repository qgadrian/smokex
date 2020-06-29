ExUnit.start()
:ok = Ecto.Adapters.SQL.Sandbox.checkout(Smokex.Repo)
Ecto.Adapters.SQL.Sandbox.mode(Smokex.Repo, {:shared, self()})
