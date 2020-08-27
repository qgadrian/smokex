defmodule SmokexWeb.Telemetry.Reporter do
  @moduledoc """
  Module that provides functions to send telemetry events.
  """

  @spec execute(
          :telemetry.event_name(),
          :telemetry.event_measurements(),
          :telemetry.event_metadata()
        ) :: :ok
  def execute(event_name, measurement \\ %{}, metadata \\ %{}) do
    :telemetry.execute(build_event_name(event_name), measurement, metadata)
  end

  #
  # Private functions
  #

  defp build_event_name(event_name) do
    [:smokex_web] ++ event_name
  end
end
