defmodule SmokexClient.Utils.Map.FromStruct do
  def from_struct(struct) when is_struct(struct) do
    map = Map.from_struct(struct)

    :maps.map(&nested_from_struct/2, map)
  end

  defp nested_from_struct(_key, value), do: ensure_nested_map(value)

  defp ensure_nested_map(list) when is_list(list), do: Enum.map(list, &ensure_nested_map/1)

  @skip_structs [Date, DateTime, NaiveDateTime, Time]
  defp ensure_nested_map(%{__struct__: struct} = data) when struct in @skip_structs, do: data

  defp ensure_nested_map(%{__struct__: _} = struct) do
    map = Map.from_struct(struct)

    :maps.map(&nested_from_struct/2, map)
  end

  defp ensure_nested_map(data), do: data
end
