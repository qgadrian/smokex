# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config

# Configure Mix tasks and generators
config :smokex,
  ecto_repos: [Smokex.Repo]

config :smokex_web,
  ecto_repos: [Smokex.Repo],
  generators: [context_app: :smokex],
  enable_system_metrics: true

# Configures the endpoint
config :smokex_web, SmokexWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "vpUtc18TGQky8gWkKi0MQmw3MWUf2M02Pu4+6tv+J3Pq1evb333B4/azjwWf2yUh",
  render_errors: [view: SmokexWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Smokex.PubSub,
  live_view: [signing_salt: "***REMOVED***"]

# Configures Elixir's Logger
config :logger,
  backends: [:console, Sentry.LoggerBackend],
  handle_otp_reports: true,
  handle_sasl_reports: false

logger_metadata = [
  :request_id,
  :mfa,
  :file,
  :line,
  :pid,
  :stripe_event,
  :stripe_customer_id,
  :stripe_subscription_id,
  :user_id
]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: logger_metadata

config :logger, Sentry.LoggerBackend,
  capture_log_messages: true,
  level: :warn,
  metadata: logger_metadata

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :smokex_client,
  timeout: 10000,
  verbose: true,
  quiet: false,
  halt_on_error: true

config :smokex_web, :pow,
  controller_callbacks: Pow.Extension.Phoenix.ControllerCallbacks,
  extensions: [PowResetPassword, PowEmailConfirmation],
  mailer_backend: SmokexWeb.Pow.Mailer,
  repo: Smokex.Repo,
  routes_backend: SmokexWeb.Pow.Routes,
  user: Smokex.Users.User,
  users_context: Smokex.Users,
  web_mailer_module: SmokexWeb,
  web_module: SmokexWeb

config :stripity_stripe,
  publishable_api_key:
    "***REMOVED***",
  api_key:
    "***REMOVED***",
  signing_secret: "***REMOVED***"

config :sentry,
  dsn: "***REMOVED***",
  environment_name: Mix.env(),
  included_environments: [:prod],
  enable_source_code_context: true,
  root_source_code_path: File.cwd!()

# See:
# https://github.com/sorentwo/oban#configuring-queues
config :smokex, Oban,
  repo: Smokex.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [plan_executions: 50]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
