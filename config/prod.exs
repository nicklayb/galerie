import Config

config :nectarine, NectarineWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  check_origin: false,
  server: true

config :logger, level: :info
