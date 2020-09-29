defmodule Smokex.Ecto.EncryptedMap do
  use Cloak.Ecto.Map, vault: Smokex.Ecto.Vault
end
