import Config

config :smokex_web, SmokexWeb.Endpoint,
  http: [port: {:system, "PORT"}],
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
  server: true,
  url: [port: 443]

config :smokex, Smokex.Repo,
  database: System.fetch_env!("DATABASE_NAME"),
  pool_size: System.fetch_env!("POOL_SIZE") |> String.to_integer(),
  url: System.fetch_env!("DATABASE_URL")

config :stripity_stripe,
  api_key: System.fetch_env!("STRIPE_API_KEY"),
  signing_secret: System.fetch_env!("STRIPE_SIGNING_SECRET")
