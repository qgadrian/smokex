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
  Converts a expected value from an assertion.

  The expected value can be:

  * A map or a list or received elements
  * A list of received headers
  """
  @spec expect_value_to_string(failed_assertions :: map) :: String.t()
  def expect_value_to_string(%{"expected" => expected})
      when is_map(expected) or is_list(expected) do
    Jason.encode!(expected, pretty: true)
  end

  def expect_value_to_string(expected_list) when is_list(expected_list) do
    Enum.map(expected_list, fn %{"expected" => expected, "header" => header_name} ->
      "#{header_name}: #{expected}\n"
    end)
  end

  def expect_value_to_string(%{"expected" => expected}) do
    inspect(expected)
  end

  def expect_value_to_string(message), do: inspect(message)

  @doc """
  Converts a received value from an assertion.

  The received value can be:

  * A map or a list or received elements
  * A list of received headers
  """
  @spec received_value_to_string(failed_assertions :: map) :: String.t()
  def received_value_to_string(%{"received" => received})
      when is_map(received) or is_list(received) do
    Jason.encode!(received, pretty: true)
  end

  def received_value_to_string(received_list) when is_list(received_list) do
    Enum.map(received_list, fn
      %{"received" => nil, "header" => header_name} ->
        "`#{header_name}` not present\n"

      %{"received" => received, "header" => header_name} ->
        "#{header_name}: #{received}\n"
    end)
  end

  def received_value_to_string(%{"received" => received}) do
    inspect(received)
  end

  def received_value_to_string(message), do: inspect(message)
end
