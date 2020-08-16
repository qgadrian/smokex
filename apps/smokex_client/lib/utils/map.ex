defmodule SmokexClient.Utils.Map do
  defdelegate key_paths(struct), to: __MODULE__.KeyPaths
  defdelegate from_struct(struct), to: __MODULE__.FromStruct
end
