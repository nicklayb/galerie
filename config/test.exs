import Config

config :nectarine, Nectarine.Repo,
  username: "postgres",
  password: "postgres",
  database: "nectarine_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :nectarine, NectarineWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn, backends: []
