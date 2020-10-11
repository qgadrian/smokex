defmodule SmokexWeb.PlansExecutionsLive.Components.Show.Row do
  use SmokexWeb, :live_component

  alias Smokex.Results
  alias SmokexWeb.Results.Components.ActionBadge
  alias SmokexWeb.Results.Components.RuntimeLabel
  alias SmokexWeb.Results.Components.StatusBadge
  alias SmokexWeb.Results.Components.TimeAgoLabel

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  #
  # Private functions
  #

  @doc """
  Converts a expected/received value from an assertion.
  """
  @spec value_to_string(expected_value :: term) :: String.t() | number | boolean
  def value_to_string(expected)
      when is_map(expected) or is_list(expected) do
    Jason.encode!(expected, pretty: true)
  end

  def value_to_string(nil), do: "-"

  def value_to_string(expected), do: expected
end
