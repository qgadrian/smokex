import Config

config :smokex_web, SmokexWeb.Endpoint,
  http: [port: {:system, "PORT"}],
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
  server: true,
  url: [port: 443],
  live_view: [signing_salt: System.fetch_env!("LIVEVIEW_SIGNING_SALT")]

config :smokex, Smokex.Repo,
  username: System.fetch_env!("DATABASE_USERNAME"),
  password: System.fetch_env!("DATABASE_PASSWORD"),
  database: System.fetch_env!("DATABASE_NAME"),
  hostname: System.fetch_env!("DATABASE_HOSTNAME"),
  port: System.fetch_env!("DATABASE_PORT"),
  pool_size: System.fetch_env!("POOL_SIZE") |> String.to_integer(),
  ssl: String.to_existing_atom(System.get_env("DATABASE_SSL_ENABLED", "true"))

config :stripity_stripe,
  api_key: System.fetch_env!("STRIPE_API_KEY"),
  publishable_api_key: System.fetch_env!("STRIPE_PUBLISHABLE_API_KEY"),
  signing_secret: System.fetch_env!("STRIPE_SIGNING_SECRET")

config :smokex,
  stripe_price_id: System.fetch_env!("STRIPE_PRICE_ID"),
  enable_email_notifications:
    String.downcase(System.fetch_env!("ENABLE_EMAIL_NOTIFICATIONS")) == "true",
  limit_executions_expires_after_hours:
    "LIMIT_EXECUTIONS_EXPIRES_AFTER_HOURS" |> System.fetch_env!() |> String.to_integer(),
  limit_executions_per_period:
    "LIMIT_EXECUTIONS_PER_PERIOD" |> System.fetch_env!() |> String.to_integer(),
  limit_plan_definitions_per_organization:
    "LIMIT_PLAN_DEFINITIONS_PER_ORGANIZATION" |> System.fetch_env!() |> String.to_integer()

config :smokex_web, :basic_auth,
  username: System.fetch_env!("DASHBOARD_AUTH_USERNAME"),
  password: System.fetch_env!("DASHBOARD_AUTH_PASSWORD")

config :slack,
  client_id: System.fetch_env!("SLACK_CLIENT_ID"),
  client_secret: System.fetch_env!("SLACK_CLIENT_SECRET")

config :sentry,
  dsn: System.fetch_env!("SENTRY_DSN")

config :smokex_web, SmokexWeb.Pow.Mailer, api_key: System.fetch_env!("SENDGRID_API_KEY")

#
# To change the cypher key see:
# https://hexdocs.pm/cloak_ecto/rotate_keys.html#content
config :smokex, Smokex.Ecto.Vault,
  ciphers: [
    default: {
      Cloak.Ciphers.AES.GCM,
      tag: "AES.GCM.V2",
      key: System.fetch_env!("ECTO_CYPHER_KEY") |> Base.decode64!(),
      iv_length: 12
    }
  ]
