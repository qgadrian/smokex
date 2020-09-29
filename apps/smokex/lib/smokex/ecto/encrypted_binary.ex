defmodule Smokex.Ecto.EncryptedBinary do
  use Cloak.Ecto.Binary, vault: Smokex.Ecto.Vault
end
