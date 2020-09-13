defmodule SmokexWeb.Telemetry.ObanErrorReporter do
  def handle_event([:oban, :job, :exception], measure, meta, _) do
    extra =
      meta
      |> Map.take([:id, :args, :queue, :worker])
      |> Map.merge(measure)

    log_and_report(meta)
  end

  def handle_event([:oban, :circuit, :trip], _measure, meta, _) do
    log_and_report(meta)
  end

  defp log_and_report(meta) do
    Logger.error("#{inspect meta}")
    Sentry.capture_exception(meta.error, stracktrace: meta.stacktrace, extra: extra)
  end
end
