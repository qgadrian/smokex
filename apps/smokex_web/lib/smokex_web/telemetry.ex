defmodule SmokexWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  @enable_system_metrics Application.compile_env(:smokex_web, :enable_system_metrics, true)
  @metrics_reporters Application.compile_env(:smokex_web, :metrics_reporters, [])

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children =
      [
        # Telemetry poller will execute the given period measurements
        # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
        {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      ] ++ metrics_reporters()

    attach_oban_handlers()

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp metrics_reporters do
    Enum.reduce(@metrics_reporters, [], fn
      :console, acc ->
        [{Telemetry.Metrics.ConsoleReporter, metrics: metrics()} | acc]

      :statsd, acc ->
        [
          {TelemetryMetricsStatsd,
           [
             metrics: metrics(),
             formatter: :datadog
           ]}
          | acc
        ]
    end)
  end

  def metrics do
    system_metrics() ++ custom_metrics()
  end

  defp system_metrics() do
    if @enable_system_metrics do
      [
        # Phoenix Metrics
        summary("phoenix.endpoint.stop.duration",
          unit: {:native, :millisecond}
        ),
        summary("phoenix.router_dispatch.stop.duration",
          tags: [:route],
          unit: {:native, :millisecond}
        ),

        # Tesla Metrics
        summary("tesla.request.start.system_time", unit: {:native, :millisecond}, tags: [:env]),
        summary("tesla.request.stop.duration", unit: {:native, :millisecond}, tags: [:env, :error]),
        summary("tesla.request.exception.duration",
          unit: {:native, :millisecond},
          tags: [:kind, :reason]
        ),

        # Database Metrics
        summary("smokex.repo.query.total_time", unit: {:native, :millisecond}),
        summary("smokex.repo.query.decode_time", unit: {:native, :millisecond}),
        summary("smokex.repo.query.query_time", unit: {:native, :millisecond}),
        summary("smokex.repo.query.queue_time", unit: {:native, :millisecond}),
        summary("smokex.repo.query.idle_time", unit: {:native, :millisecond}),

        # VM Metrics
        summary("vm.memory.total", unit: {:byte, :kilobyte}),
        summary("vm.total_run_queue_lengths.total"),
        summary("vm.total_run_queue_lengths.cpu"),
        summary("vm.total_run_queue_lengths.io")
      ]
    else
      []
    end
  end

  defp custom_metrics do
    [
      counter("smokex_web.plan_definition.action",
        measurement: :action,
        tags: [:id, :result, :action]
      ),
      counter("smokex_web.plan_execution.action",
        measurement: :action,
        tags: [:id, :result, :status, :action, :plan_definition_id]
      ),
      summary("smokex.plan_execution.execution_time",
        measurement: :execution_time,
        tags: [:id, :status],
        unit: {:native, :second}
      ),

      # User sessions
      summary("smokex_web.session_count.count")
    ]
  end

  defp periodic_measurements do
    if @enable_system_metrics do
      [
        # A module, function and arguments to be invoked periodically.
        # This function must call :telemetry.execute/3 and a metric must be added above.
        {SmokexWeb.Telemetry.CurrentSessionCount, :dispatch_session_count, []}
      ]
    else
      []
    end
  end

  defp attach_oban_handlers do
    :ok = Oban.Telemetry.attach_default_logger()

    :telemetry.attach_many(
      "oban-errors",
      [[:oban, :job, :exception], [:oban, :circuit, :trip]],
      &SmokexWeb.Telemetry.ObanErrorReporter.handle_event/4,
      %{}
    )

    events = [[:oban, :job, :start], [:oban, :job, :stop], [:oban, :job, :exception]]

    :telemetry.attach_many("oban-logger", events, &MyApp.ObanLogger.handle_event/4, [])
  end
end
