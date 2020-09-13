defmodule SmokexWeb.Telemetry.ObanErrorReporter do
  @moduledoc """
  This module handles Oban telemetry error event thrown by workers.
  """

  require Logger

  @spec handle_event(
          :telemetry.event_name(),
          :telemetry.event_measurements(),
          :telemetry.event_metadata(),
          term
        ) :: :ok
  def handle_event([:oban, :job, :exception], measure, meta, _) do
    extra =
      meta
      |> Map.take([:id, :args, :queue, :worker])
      |> Map.merge(measure)

    log_and_report(meta, extra)
  end

  def handle_event([:oban, :circuit, :trip], _measure, meta, _) do
    log_and_report(meta)
  end

  @spec log_and_report(:telemetry.event_metadata(), map) :: :ok
  defp log_and_report(meta, extra \\ %{}) do
    Logger.error("#{inspect(meta)}", extra: extra)
    Sentry.capture_exception(meta.error, stracktrace: meta.stacktrace, extra: extra)

    :ok
  end
end
