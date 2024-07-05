import Config

config :galerie, Galerie.Repo,
  username: "postgres",
  password: "postgres",
  database: "galerie_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :galerie, GalerieWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn, backends: []
