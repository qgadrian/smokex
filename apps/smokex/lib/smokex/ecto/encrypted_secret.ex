defmodule Smokex.Ecto.EncryptedToken do
  use Cloak.Ecto.Binary, vault: Smokex.Ecto.Vault
end
