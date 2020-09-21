defmodule SmokexWeb.Telemetry.ObanLogger do
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
  def handle_event([:oban, :job, :start], measure, meta, _) do
    Logger.info("[Oban] :start #{meta.worker} at #{measure.system_time}")
  end

  def handle_event([:oban, :job, :stop], measure, meta, _) do
    Logger.info("[Oban] :stop #{meta.worker} ran in #{measure.duration}")
  end

  def handle_event([:oban, :job, :exception], measure, meta, _) do
    Logger.error("[Oban] exception #{meta.worker} exception, ran for #{measure.duration}")
    Logger.error("#{inspect(meta)}")
  end
end
