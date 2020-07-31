import Config

config :smokex_web, SmokexWeb.Endpoint,
  http: [port: {:system, "PORT"}],
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
  server: true,
  url: [port: 443]

config :smokex, Smokex.Repo,
  username: System.fetch_env!("DATABASE_USERNAME"),
  password: System.fetch_env!("DATABASE_PASSWORD"),
  database: System.fetch_env!("DATABASE_NAME"),
  hostname: System.fetch_env!("DATABASE_HOSTNAME"),
  pool_size: System.fetch_env!("POOL_SIZE") |> String.to_integer()

config :stripity_stripe,
  api_key: System.fetch_env!("STRIPE_API_KEY"),
  signing_secret: System.fetch_env!("STRIPE_SIGNING_SECRET")
