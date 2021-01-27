defmodule SmokexWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      SmokexWeb.Telemetry,
      # Start the Endpoint (http/https)
      SmokexWeb.Endpoint,
      # Plug to throttle requests and avoid brute force attacks
      {PlugAttack.Storage.Ets, name: SmokexWeb.Plugs.PlugAttack, clean_period: 60_000}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SmokexWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SmokexWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
