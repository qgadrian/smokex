defmodule SmokexClient.TypeConverter do
  @moduledoc """
  Module to work with types.

  Provides useful functions to convert a string representation on the correct
  value.
  """

  @spec convert(String.t()) :: boolean | integer | String.t()
  def convert("true"), do: true
  def convert("false"), do: false

  def convert(string_or_number) when is_binary(string_or_number) do
    case Integer.parse(string_or_number) do
      {number, ""} -> number
      _error -> string_or_number
    end
  end

  def convert(other) when is_number(other) or is_boolean(other), do: other
end
