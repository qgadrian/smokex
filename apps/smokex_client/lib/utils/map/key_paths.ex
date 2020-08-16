defmodule SmokexClient.Utils.Map.KeyPaths do
  def key_paths(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> key_paths()
  end

  def key_paths(map) when is_map(map) do
    # In a simple case the result of this function will be a list of one-element lists. For example,
    #
    #     key_paths(%{k1: 1, k2: 2}) == [[:k1], [:k2]]
    #
    # However, if there are nested maps, the top-level key will be prepended to all subpaths returned from the recursive
    # calls of this function:
    #
    #     key_paths(%{k1: %{k11: 11, k12: 12}, k2: 2}) == [[:k1, :k11], [:k1, :k12], [:k2]]
    #
    # This is why we're using Enum.flat_map for the iteration here: to allow recursive function calls to return a list
    # that will then be spliced into the parent list instead of being added to the parent as a single list of lists. If
    # we were to use just Enum.map, we'd get the following result instead:
    #
    #     key_paths(%{k1: %{k11: 11, k12: 12}, k2: 2}) ==
    #       [
    #         [[:k1, :k11], [:k1, :k12]],  # return value of the first recursive call
    #         [[:k2]]
    #       ]
    #
    Enum.flat_map(map, fn
      {key, nested_map} when is_map(nested_map) ->
        # If the value is a nested map, get its list of paths recursively and prepend the current key to each of them.
        for key_list <- key_paths(nested_map) do
          [key | key_list]
        end

      {key, _val} ->
        # For plain values return the key to end the recursion. The key is wrapped in a list twice because flat_map
        # will unwrap the outermost list and the remainder will be used as a list tail by the calling function (the one
        # immediately up the stack).
        [[key]]
    end)
  end
end
