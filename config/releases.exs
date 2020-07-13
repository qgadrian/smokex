config :smokex, SmokexWeb.Endpoint,
  http: [port: {:system, "PORT"}],
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
  server: true,
  url: [port: 443]

config :smokex, Smokex.Repo, url: System.fetch_env!("DATABASE_URL")
