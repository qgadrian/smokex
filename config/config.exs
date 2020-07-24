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
  generators: [context_app: :smokex]

# Configures the endpoint
config :smokex_web, SmokexWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "vpUtc18TGQky8gWkKi0MQmw3MWUf2M02Pu4+6tv+J3Pq1evb333B4/azjwWf2yUh",
  render_errors: [view: SmokexWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Smokex.PubSub,
  live_view: [signing_salt: "***REMOVED***"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :smokex_client,
       :default_options,
       timeout: 2000,
       verbose: true,
       quiet: false

config :smokex_web, :pow,
  user: Smokex.Users.User,
  repo: Smokex.Repo,
  web_module: SmokexWeb,
  routes_backend: SmokexWeb.Pow.Routes

config :stripity_stripe,
  api_key:
    "***REMOVED***",
  signing_secret: "***REMOVED***"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
